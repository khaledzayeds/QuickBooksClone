param(
    [int]$Port = 5077,
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
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\sales-receipts"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-sales-receipts.db"

New-Item -ItemType Directory -Force -Path $SmokeRoot | Out-Null
Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue

Write-Step "Building API."
dotnet build "$RepositoryRoot\QuickBooksClone.Api\QuickBooksClone.Api.csproj" --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q
if ($LASTEXITCODE -ne 0) {
    throw "Build failed."
}

$api = $null
try {
    Write-Step "Starting API on $BaseUrl with temporary SQLite database."
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath

    $accounts = Invoke-Json -Method Get -Uri "$BaseUrl/api/accounts?pageSize=100"
    $bankAccount = $accounts.items | Where-Object { $_.accountType -eq 1 } | Select-Object -First 1
    $incomeAccount = $accounts.items | Where-Object { $_.name -eq "Sales Income" } | Select-Object -First 1
    $inventoryAccount = $accounts.items | Where-Object { $_.name -eq "Inventory Asset" } | Select-Object -First 1
    $cogsAccount = $accounts.items | Where-Object { $_.name -eq "Cost of Goods Sold" } | Select-Object -First 1
    $expenseAccount = $accounts.items | Where-Object { $_.name -eq "General Expenses" } | Select-Object -First 1
    $customer = (Invoke-Json -Method Get -Uri "$BaseUrl/api/customers?pageSize=1").items[0]
    $stamp = Get-Date -Format "yyyyMMddHHmmss"
    $item = Invoke-Json -Method Post -Uri "$BaseUrl/api/items" -Body @{
        name = "Sales Receipt Inventory $stamp"
        itemType = 1
        sku = "SR-INV-$stamp"
        barcode = "SR-BC-$stamp"
        salesPrice = 100
        purchasePrice = 40
        quantityOnHand = 2
        unit = "pcs"
        incomeAccountId = $incomeAccount.id
        inventoryAssetAccountId = $inventoryAccount.id
        cogsAccountId = $cogsAccount.id
        expenseAccountId = $expenseAccount.id
    }
    $itemBefore = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    $customerBefore = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers/$($customer.id)"

    Assert-True ($null -ne $bankAccount) "Expected a seeded bank account."
    Assert-True ($null -ne $incomeAccount -and $null -ne $inventoryAccount -and $null -ne $cogsAccount -and $null -ne $expenseAccount) "Expected seeded posting accounts for inventory item creation."

    Write-Step "Creating a posted sales receipt."
    $receipt = Invoke-Json -Method Post -Uri "$BaseUrl/api/sales-receipts" -Body @{
        customerId = $customer.id
        receiptDate = "2026-04-20"
        depositAccountId = $bankAccount.id
        paymentMethod = "Cash"
        lines = @(
            @{
                itemId = $item.id
                description = "Sales receipt smoke"
                quantity = 1
                unitPrice = 100
                discountPercent = 0
            }
        )
    }

    Assert-True ($receipt.invoiceNumber -like "SR-*") "Sales receipt should use SR numbering."
    Assert-True ($receipt.status -eq 4) "Sales receipt should auto-finish as Paid."
    Assert-True ($null -ne $receipt.receiptPaymentId) "Sales receipt should link a receipt payment."
    Assert-True ($receipt.balanceDue -eq 0) "Sales receipt should have zero balance due."

    $payments = Invoke-Json -Method Get -Uri "$BaseUrl/api/payments?invoiceId=$($receipt.id)&pageSize=25"
    $saleTransactions = Invoke-Json -Method Get -Uri "$BaseUrl/api/transactions?sourceEntityType=Invoice&sourceEntityId=$($receipt.id)&pageSize=25"
    $paymentTransactions = Invoke-Json -Method Get -Uri "$BaseUrl/api/transactions?sourceEntityType=Payment&sourceEntityId=$($receipt.receiptPaymentId)&pageSize=25"
    $itemAfter = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    $customerAfter = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers/$($customer.id)"

    Assert-True ($payments.totalCount -eq 1) "Sales receipt should create one linked payment."
    Assert-True ($saleTransactions.totalCount -eq 1) "Sales receipt should create one sale transaction."
    Assert-True ($paymentTransactions.totalCount -eq 1) "Sales receipt should create one payment transaction."
    Assert-True ($itemAfter.quantityOnHand -eq ($itemBefore.quantityOnHand - 1)) "Sales receipt should reduce inventory."
    Assert-True ($customerAfter.balance -eq $customerBefore.balance) "Sales receipt should net customer balance back to zero."

    Write-Step "Voiding the sales receipt as one document."
    $voidedReceipt = Invoke-Json -Method Patch -Uri "$BaseUrl/api/sales-receipts/$($receipt.id)/void"
    $itemAfterVoid = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    $customerAfterVoid = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers/$($customer.id)"

    Assert-True ($voidedReceipt.status -eq 5) "Voided sales receipt should move to Void."
    Assert-True ($itemAfterVoid.quantityOnHand -eq $itemBefore.quantityOnHand) "Voiding sales receipt should restore inventory."
    Assert-True ($customerAfterVoid.balance -eq $customerBefore.balance) "Voiding sales receipt should leave customer balance unchanged."

    [pscustomobject]@{
        salesReceiptNumber = $receipt.invoiceNumber
        linkedPaymentId = $receipt.receiptPaymentId
        paidStatus = $receipt.status
        inventoryReduced = ($itemAfter.quantityOnHand -eq ($itemBefore.quantityOnHand - 1))
        inventoryRestoredOnVoid = ($itemAfterVoid.quantityOnHand -eq $itemBefore.quantityOnHand)
        customerBalanceStayedFlat = ($customerAfter.balance -eq $customerBefore.balance)
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
