param(
    [int]$Port = 5021,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[smoke] $Message"
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
    param(
        [System.Diagnostics.Process]$Process
    )

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

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$BaseUrl = "http://localhost:$Port"
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\persistence"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-smoke.db"

New-Item -ItemType Directory -Force -Path $SmokeRoot | Out-Null
Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue

Write-Step "Building API."
dotnet build "$RepositoryRoot\QuickBooksClone.Api\QuickBooksClone.Api.csproj" --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q

$api = $null
try {
    Write-Step "Starting API on $BaseUrl with temporary SQLite database."
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath

    Write-Step "Checking migrated database startup and seed data."
    Assert-True (Test-Path -LiteralPath $DatabasePath) "SQLite smoke database was not created."

    $accounts = Invoke-Json -Method Get -Uri "$BaseUrl/api/accounts?pageSize=50"
    Assert-True ($accounts.totalCount -ge 8) "Default accounts were not seeded."

    $incomeAccount = $accounts.items | Where-Object { $_.name -eq "Sales Income" } | Select-Object -First 1
    $inventoryAccount = $accounts.items | Where-Object { $_.name -eq "Inventory Asset" } | Select-Object -First 1
    $cogsAccount = $accounts.items | Where-Object { $_.name -eq "Cost of Goods Sold" } | Select-Object -First 1
    $expenseAccount = $accounts.items | Where-Object { $_.name -eq "General Expenses" } | Select-Object -First 1
    Assert-True ($null -ne $incomeAccount -and $null -ne $inventoryAccount -and $null -ne $cogsAccount -and $null -ne $expenseAccount) "Required posting accounts were not seeded."

    $stamp = Get-Date -Format "yyyyMMddHHmmss"

    Write-Step "Creating a posted credit invoice and checking accounting effects."
    $customer = Invoke-Json -Method Post -Uri "$BaseUrl/api/customers" -Body @{
        displayName = "Smoke Customer $stamp"
        companyName = "Smoke Co"
        email = "smoke-customer-$stamp@example.com"
        phone = "+2000000000"
        currency = "EGP"
        openingBalance = 0
    }

    $item = Invoke-Json -Method Post -Uri "$BaseUrl/api/items" -Body @{
        name = "Smoke Inventory Item $stamp"
        itemType = 1
        sku = "SMOKE-INV-$stamp"
        barcode = "SMOKE-BC-$stamp"
        salesPrice = 100
        purchasePrice = 40
        quantityOnHand = 5
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
                description = "Smoke sale"
                quantity = 2
                unitPrice = 100
                discountPercent = 0
            }
        )
    }

    $postedItem = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    $postedCustomer = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers/$($customer.id)"
    $transactions = Invoke-Json -Method Get -Uri "$BaseUrl/api/transactions?sourceEntityType=Invoice&sourceEntityId=$($invoice.id)&pageSize=25"

    Assert-True ($invoice.status -eq 6) "Invoice was not posted."
    Assert-True ($postedItem.quantityOnHand -eq 3) "Posted invoice did not reduce inventory quantity."
    Assert-True ($postedCustomer.balance -eq 200) "Posted credit invoice did not update customer balance."
    Assert-True ($transactions.totalCount -eq 1) "Posted invoice transaction was not created."

    Write-Step "Checking failed posting rollback."
    $invoicesBeforeFailure = Invoke-Json -Method Get -Uri "$BaseUrl/api/invoices?pageSize=100"

    $rollbackItem = Invoke-Json -Method Post -Uri "$BaseUrl/api/items" -Body @{
        name = "Rollback Inventory Item $stamp"
        itemType = 1
        sku = "ROLLBACK-INV-$stamp"
        barcode = "ROLLBACK-BC-$stamp"
        salesPrice = 100
        purchasePrice = 40
        quantityOnHand = 0
        unit = "pcs"
        incomeAccountId = $incomeAccount.id
        inventoryAssetAccountId = $inventoryAccount.id
        cogsAccountId = $cogsAccount.id
        expenseAccountId = $expenseAccount.id
    }

    $postingFailed = $false
    try {
        Invoke-Json -Method Post -Uri "$BaseUrl/api/invoices" -Body @{
            customerId = $customer.id
            invoiceDate = "2026-04-19"
            dueDate = "2026-04-19"
            saveMode = 2
            paymentMode = 1
            depositAccountId = $null
            paymentMethod = $null
            lines = @(
                @{
                    itemId = $rollbackItem.id
                    description = "Should rollback"
                    quantity = 1
                    unitPrice = 100
                    discountPercent = 0
                }
            )
        } | Out-Null
    }
    catch {
        $postingFailed = $true
    }

    $invoicesAfterFailure = Invoke-Json -Method Get -Uri "$BaseUrl/api/invoices?pageSize=100"
    Assert-True $postingFailed "Insufficient stock invoice unexpectedly succeeded."
    Assert-True ($invoicesBeforeFailure.totalCount -eq $invoicesAfterFailure.totalCount) "Failed posting left a saved invoice behind."

    Write-Step "Restarting API to verify persistence."
    Stop-SmokeApi -Process $api
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath

    $persistedInvoice = Invoke-Json -Method Get -Uri "$BaseUrl/api/invoices/$($invoice.id)"
    $persistedItem = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    $persistedCustomer = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers/$($customer.id)"

    Assert-True ($persistedInvoice.id -eq $invoice.id) "Posted invoice did not persist after restart."
    Assert-True ($persistedItem.quantityOnHand -eq 3) "Inventory quantity did not persist after restart."
    Assert-True ($persistedCustomer.balance -eq 200) "Customer balance did not persist after restart."

    [pscustomobject]@{
        databaseCreated = Test-Path -LiteralPath $DatabasePath
        accountCount = $accounts.totalCount
        postedInvoiceNumber = $invoice.invoiceNumber
        postedInvoiceStatus = $invoice.status
        itemQuantityAfterSale = $postedItem.quantityOnHand
        customerBalanceAfterSale = $postedCustomer.balance
        rollbackWorked = $postingFailed -and ($invoicesBeforeFailure.totalCount -eq $invoicesAfterFailure.totalCount)
        restartPersistenceWorked = $persistedInvoice.id -eq $invoice.id -and $persistedItem.quantityOnHand -eq 3 -and $persistedCustomer.balance -eq 200
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
