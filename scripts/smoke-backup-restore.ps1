param(
    [int]$Port = 5034,
    [switch]$KeepArtifacts
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[backup-smoke] $Message"
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
        [Parameter(Mandatory = $true)][string]$DatabasePath,
        [Parameter(Mandatory = $true)][string]$BackupDirectory
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
    $startInfo.Environment["Database__BackupDirectory"] = $BackupDirectory
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

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$BaseUrl = "http://localhost:$Port"
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\backup-restore"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-backup-smoke.db"
$BackupDirectory = Join-Path $SmokeRoot "backups"

New-Item -ItemType Directory -Force -Path $SmokeRoot, $BackupDirectory | Out-Null
Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
Get-ChildItem -LiteralPath $BackupDirectory -Filter *.db -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Step "Building API."
dotnet build "$RepositoryRoot\QuickBooksClone.Api\QuickBooksClone.Api.csproj" --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q

$api = $null
try {
    Write-Step "Starting API with temporary SQLite database and backup directory."
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath -BackupDirectory $BackupDirectory

    $status = Invoke-Json -Method Get -Uri "$BaseUrl/api/database/status"
    Assert-True ($status.supportsBackupRestore -eq $true) "Database status did not report SQLite backup support."
    Assert-True ($status.backupCount -eq 0) "Backup directory should be empty at the start of smoke test."

    $accounts = Invoke-Json -Method Get -Uri "$BaseUrl/api/accounts?pageSize=50"
    $incomeAccount = $accounts.items | Where-Object { $_.name -eq "Sales Income" } | Select-Object -First 1
    $inventoryAccount = $accounts.items | Where-Object { $_.name -eq "Inventory Asset" } | Select-Object -First 1
    $cogsAccount = $accounts.items | Where-Object { $_.name -eq "Cost of Goods Sold" } | Select-Object -First 1
    $expenseAccount = $accounts.items | Where-Object { $_.name -eq "General Expenses" } | Select-Object -First 1

    $stamp = Get-Date -Format "yyyyMMddHHmmss"
    Write-Step "Creating baseline business data before backup."
    $customer = Invoke-Json -Method Post -Uri "$BaseUrl/api/customers" -Body @{
        displayName = "Backup Smoke Customer $stamp"
        companyName = "Backup Co"
        email = "backup-customer-$stamp@example.com"
        phone = "+2000000002"
        currency = "EGP"
        openingBalance = 0
    }

    $item = Invoke-Json -Method Post -Uri "$BaseUrl/api/items" -Body @{
        name = "Backup Smoke Inventory $stamp"
        itemType = 1
        sku = "BACKUP-INV-$stamp"
        barcode = "BACKUP-BC-$stamp"
        salesPrice = 120
        purchasePrice = 45
        quantityOnHand = 3
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
                description = "Backup smoke sale"
                quantity = 1
                unitPrice = 120
                discountPercent = 0
            }
        )
    }

    $baselineCustomer = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers/$($customer.id)"
    $baselineItem = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    Assert-True ($baselineCustomer.balance -eq 120) "Baseline customer balance before backup is wrong."
    Assert-True ($baselineItem.quantityOnHand -eq 2) "Baseline inventory quantity before backup is wrong."

    Write-Step "Creating database backup."
    $createdBackup = Invoke-Json -Method Post -Uri "$BaseUrl/api/database/backups" -Body @{
        label = "smoke"
    }

    $backupsAfterCreate = Invoke-Json -Method Get -Uri "$BaseUrl/api/database/backups"
    Assert-True ($backupsAfterCreate.totalCount -eq 1) "Backup list should contain one backup after creation."
    Assert-True ($createdBackup.fileName -eq $backupsAfterCreate.items[0].fileName) "Created backup was not returned by list endpoint."

    Write-Step "Changing live data after backup so restore has something to undo."
    $extraCustomer = Invoke-Json -Method Post -Uri "$BaseUrl/api/customers" -Body @{
        displayName = "Backup Smoke Extra Customer $stamp"
        companyName = "Backup Extra Co"
        email = "backup-extra-$stamp@example.com"
        phone = "+2000000003"
        currency = "EGP"
        openingBalance = 0
    }

    $mutatedInvoice = Invoke-Json -Method Post -Uri "$BaseUrl/api/invoices" -Body @{
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
                description = "Post-backup mutation"
                quantity = 1
                unitPrice = 120
                discountPercent = 0
            }
        )
    }

    $mutatedCustomer = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers/$($customer.id)"
    $mutatedItem = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    Assert-True ($mutatedCustomer.balance -eq 240) "Mutation did not update customer balance."
    Assert-True ($mutatedItem.quantityOnHand -eq 1) "Mutation did not update inventory quantity."

    Write-Step "Restoring backup with safety backup enabled."
    $restoreResult = Invoke-Json -Method Post -Uri "$BaseUrl/api/database/backups/restore" -Body @{
        fileName = $createdBackup.fileName
        createSafetyBackup = $true
    }

    Assert-True ($restoreResult.createdSafetyBackup -eq $true) "Restore should create a safety backup by default."

    $restoredCustomer = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers/$($customer.id)"
    $restoredItem = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    $restoredInvoice = Invoke-Json -Method Get -Uri "$BaseUrl/api/invoices/$($invoice.id)"
    $statusAfterRestore = Invoke-Json -Method Get -Uri "$BaseUrl/api/database/status"
    $backupsAfterRestore = Invoke-Json -Method Get -Uri "$BaseUrl/api/database/backups"

    Assert-True ($restoredCustomer.balance -eq 120) "Restore did not return customer balance to the backup state."
    Assert-True ($restoredItem.quantityOnHand -eq 2) "Restore did not return inventory quantity to the backup state."
    Assert-True ($restoredInvoice.id -eq $invoice.id) "Baseline invoice was not preserved after restore."
    Assert-True ($statusAfterRestore.backupCount -ge 2) "Safety backup was not visible after restore."
    Assert-True ($backupsAfterRestore.totalCount -ge 2) "Backup list should include original backup plus safety backup."

    $extraCustomerMissing = $false
    try {
        Invoke-Json -Method Get -Uri "$BaseUrl/api/customers/$($extraCustomer.id)" | Out-Null
    }
    catch {
        $extraCustomerMissing = $true
    }

    $mutatedInvoiceMissing = $false
    try {
        Invoke-Json -Method Get -Uri "$BaseUrl/api/invoices/$($mutatedInvoice.id)" | Out-Null
    }
    catch {
        $mutatedInvoiceMissing = $true
    }

    Assert-True $extraCustomerMissing "Restore did not remove the customer created after backup."
    Assert-True $mutatedInvoiceMissing "Restore did not remove the invoice created after backup."

    [pscustomobject]@{
        backupCreated = $createdBackup.fileName
        safetyBackupCreated = $restoreResult.createdSafetyBackup
        backupCountAfterRestore = $backupsAfterRestore.totalCount
        restoredCustomerBalance = $restoredCustomer.balance
        restoredItemQuantity = $restoredItem.quantityOnHand
        removedPostBackupCustomer = $extraCustomerMissing
        removedPostBackupInvoice = $mutatedInvoiceMissing
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepArtifacts) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
        Get-ChildItem -LiteralPath $BackupDirectory -Filter *.db -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}
