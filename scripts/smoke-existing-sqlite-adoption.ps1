param(
    [int]$Port = 5030,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[adoption-smoke] $Message"
}

function Invoke-Json {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [object]$Body = $null
    )

    if ($null -eq $Body) {
        return Invoke-RestMethod -Method $Method -Uri $Uri -TimeoutSec 30
    }

    $json = $Body | ConvertTo-Json -Depth 10
    return Invoke-RestMethod -Method $Method -Uri $Uri -ContentType "application/json" -Body $json -TimeoutSec 30
}

function Wait-ForApi {
    param(
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [int]$Attempts = 90
    )

    for ($i = 0; $i -lt $Attempts; $i++) {
        try {
            Invoke-Json -Method Get -Uri "$BaseUrl/api/accounts?pageSize=1" | Out-Null
            return
        }
        catch {
            Start-Sleep -Milliseconds 500
        }
    }

    throw "API did not become ready at $BaseUrl."
}

function Start-SmokeApi {
    param(
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [Parameter(Mandatory = $true)][string]$DatabasePath
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = "dotnet"
    $startInfo.Arguments = "QuickBooksClone.Api\bin\Debug\net10.0\QuickBooksClone.Api.dll"
    $startInfo.WorkingDirectory = $RepositoryRoot
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $false
    $startInfo.RedirectStandardError = $false
    $startInfo.Environment["ASPNETCORE_URLS"] = $BaseUrl
    $startInfo.Environment["ASPNETCORE_ENVIRONMENT"] = "Development"
    $startInfo.Environment["Database__Provider"] = "Sqlite"
    $startInfo.Environment["ConnectionStrings__QuickBooksClone"] = "Data Source=$DatabasePath"
    $startInfo.Environment["Logging__LogLevel__Default"] = "Warning"
    $startInfo.Environment["Logging__LogLevel__Microsoft.AspNetCore"] = "Warning"

    $process = [System.Diagnostics.Process]::Start($startInfo)
    try {
        Wait-ForApi -BaseUrl $BaseUrl
        return $process
    }
    catch {
        Stop-SmokeApi -Process $process
        throw
    }
}

function Stop-SmokeApi {
    param([System.Diagnostics.Process]$Process)

    if ($null -eq $Process) {
        return
    }

    if (-not $Process.HasExited) {
        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
        $Process.WaitForExit()
    }
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Invoke-SqliteNonQuery {
    param(
        [Parameter(Mandatory = $true)][string]$DatabasePath,
        [Parameter(Mandatory = $true)][string]$CommandText
    )

    $script = @"
import sqlite3
conn = sqlite3.connect(r'''$DatabasePath''')
try:
    conn.executescript(r'''$CommandText''')
    conn.commit()
finally:
    conn.close()
"@

    $script | python -
}

function Invoke-SqliteScalar {
    param(
        [Parameter(Mandatory = $true)][string]$DatabasePath,
        [Parameter(Mandatory = $true)][string]$CommandText
    )

    $script = @"
import sqlite3
conn = sqlite3.connect(r'''$DatabasePath''')
try:
    cursor = conn.execute(r'''$CommandText''')
    row = cursor.fetchone()
    print("" if row is None or row[0] is None else row[0])
finally:
    conn.close()
"@

    return ($script | python -).Trim()
}

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$BaseUrl = "http://localhost:$Port"
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\existing-sqlite-adoption"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-adoption-smoke.db"

New-Item -ItemType Directory -Force -Path $SmokeRoot | Out-Null
Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue

Write-Step "Building API."
dotnet build "$RepositoryRoot\QuickBooksClone.Api\QuickBooksClone.Api.csproj" --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q

$api = $null
try {
    Write-Step "Creating a real database with current API."
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath

    $accounts = Invoke-Json -Method Get -Uri "$BaseUrl/api/accounts?pageSize=50"
    $incomeAccount = $accounts.items | Where-Object { $_.name -eq "Sales Income" } | Select-Object -First 1
    $inventoryAccount = $accounts.items | Where-Object { $_.name -eq "Inventory Asset" } | Select-Object -First 1
    $cogsAccount = $accounts.items | Where-Object { $_.name -eq "Cost of Goods Sold" } | Select-Object -First 1
    $expenseAccount = $accounts.items | Where-Object { $_.name -eq "General Expenses" } | Select-Object -First 1
    Assert-True ($accounts.totalCount -eq 8) "Expected exactly 8 seeded accounts in the baseline database."

    $stamp = Get-Date -Format "yyyyMMddHHmmss"
    $customer = Invoke-Json -Method Post -Uri "$BaseUrl/api/customers" -Body @{
        displayName = "Adoption Smoke Customer $stamp"
        companyName = "Adoption Co"
        email = "adoption-customer-$stamp@example.com"
        phone = "+2000000001"
        currency = "EGP"
        openingBalance = 0
    }

    $item = Invoke-Json -Method Post -Uri "$BaseUrl/api/items" -Body @{
        name = "Adoption Inventory Item $stamp"
        itemType = 1
        sku = "ADOPT-INV-$stamp"
        barcode = "ADOPT-BC-$stamp"
        salesPrice = 150
        purchasePrice = 50
        quantityOnHand = 4
        unit = "pcs"
        incomeAccountId = $incomeAccount.id
        inventoryAssetAccountId = $inventoryAccount.id
        cogsAccountId = $cogsAccount.id
        expenseAccountId = $expenseAccount.id
    }

    $invoice = Invoke-Json -Method Post -Uri "$BaseUrl/api/invoices" -Body @{
        customerId = $customer.id
        invoiceDate = "2026-04-19"
        dueDate = "2026-04-19"
        saveMode = 2
        paymentMode = 1
        depositAccountId = $null
        paymentMethod = $null
        lines = @(
            @{
                itemId = $item.id
                description = "Adoption smoke sale"
                quantity = 1
                unitPrice = 150
                discountPercent = 0
            }
        )
    }

    $baselineInvoice = Invoke-Json -Method Get -Uri "$BaseUrl/api/invoices/$($invoice.id)"
    $baselineCustomer = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers/$($customer.id)"
    $baselineItem = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    $baselineTransactions = Invoke-Json -Method Get -Uri "$BaseUrl/api/transactions?sourceEntityType=Invoice&sourceEntityId=$($invoice.id)&pageSize=10"

    Assert-True ($baselineInvoice.status -eq 6) "Baseline invoice was not posted before adoption test."
    Assert-True ($baselineCustomer.balance -eq 150) "Baseline customer balance did not update before adoption test."
    Assert-True ($baselineItem.quantityOnHand -eq 3) "Baseline inventory quantity did not update before adoption test."
    Assert-True ($baselineTransactions.totalCount -eq 1) "Baseline accounting transaction missing before adoption test."

    Write-Step "Simulating old EnsureCreated database by removing migration history."
    Stop-SmokeApi -Process $api
    $api = $null

    Invoke-SqliteNonQuery -DatabasePath $DatabasePath -CommandText 'DROP TABLE IF EXISTS "__EFMigrationsHistory";'
    $historyCountBefore = [int](Invoke-SqliteScalar -DatabasePath $DatabasePath -CommandText "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = '__EFMigrationsHistory';")
    Assert-True ($historyCountBefore -eq 0) "Failed to remove EF migration history table."

    Write-Step "Starting API again to adopt the old-style SQLite database."
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath

    $historyCountAfter = [int](Invoke-SqliteScalar -DatabasePath $DatabasePath -CommandText "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = '__EFMigrationsHistory';")
    $migrationRowCount = [int](Invoke-SqliteScalar -DatabasePath $DatabasePath -CommandText 'SELECT COUNT(*) FROM "__EFMigrationsHistory" WHERE "MigrationId" = ''20260419042720_InitialCreate'';')

    $adoptedAccounts = Invoke-Json -Method Get -Uri "$BaseUrl/api/accounts?pageSize=50"
    $adoptedInvoice = Invoke-Json -Method Get -Uri "$BaseUrl/api/invoices/$($invoice.id)"
    $adoptedCustomer = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers/$($customer.id)"
    $adoptedItem = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    $adoptedTransactions = Invoke-Json -Method Get -Uri "$BaseUrl/api/transactions?sourceEntityType=Invoice&sourceEntityId=$($invoice.id)&pageSize=10"

    Assert-True ($historyCountAfter -eq 1) "API did not recreate EF migration history table."
    Assert-True ($migrationRowCount -eq 1) "API did not adopt the existing SQLite schema into migration history."
    Assert-True ($adoptedAccounts.totalCount -eq 8) "Seed accounts were duplicated during adoption."
    Assert-True ($adoptedInvoice.id -eq $invoice.id) "Existing invoice was not readable after adoption."
    Assert-True ($adoptedCustomer.id -eq $customer.id) "Existing customer was not readable after adoption."
    Assert-True ($adoptedItem.id -eq $item.id) "Existing item was not readable after adoption."
    Assert-True ($adoptedCustomer.balance -eq 150) "Existing customer balance changed during adoption."
    Assert-True ($adoptedItem.quantityOnHand -eq 3) "Existing inventory quantity changed during adoption."
    Assert-True ($adoptedTransactions.totalCount -eq 1) "Existing accounting transaction was not readable after adoption."

    [pscustomobject]@{
        migrationHistoryRecreated = $historyCountAfter -eq 1
        migrationRowInserted = $migrationRowCount -eq 1
        accountCountAfterAdoption = $adoptedAccounts.totalCount
        preservedInvoiceId = $adoptedInvoice.id
        preservedCustomerBalance = $adoptedCustomer.balance
        preservedItemQuantity = $adoptedItem.quantityOnHand
        transactionReadableAfterAdoption = $adoptedTransactions.totalCount -eq 1
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
