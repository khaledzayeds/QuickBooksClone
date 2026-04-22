param(
    [int]$Port = 5089,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[bill-receipt-smoke] $Message"
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
    param([string]$BaseUrl, [int]$Attempts = 90)

    for ($i = 0; $i -lt $Attempts; $i++) {
        try {
            Invoke-Json -Method Get -Uri "$BaseUrl/api/settings/runtime" | Out-Null
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
        [string]$BaseUrl,
        [string]$DatabasePath
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
    param([bool]$Condition, [string]$Message)

    if (-not $Condition) {
        throw $Message
    }
}

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$BaseUrl = "http://localhost:$Port"
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\bills-against-receipts"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-bills-receipts-smoke.db"

New-Item -ItemType Directory -Force -Path $SmokeRoot | Out-Null
Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue

Write-Step "Building API."
dotnet build "$RepositoryRoot\QuickBooksClone.Api\QuickBooksClone.Api.csproj" --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q

$api = $null
try {
    Write-Step "Starting API on $BaseUrl with temporary SQLite database."
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath

    $vendors = Invoke-Json -Method Get -Uri "$BaseUrl/api/vendors?page=1&pageSize=10"
    $items = Invoke-Json -Method Get -Uri "$BaseUrl/api/items?page=1&pageSize=20"

    $vendor = $vendors.items[0]
    $item = ($items.items | Where-Object { $_.itemType -eq 1 })[0]

    $beforeVendor = Invoke-Json -Method Get -Uri "$BaseUrl/api/vendors/$($vendor.id)"
    $beforeItem = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"

    Write-Step "Creating and posting inventory receipt."
    $receipt = Invoke-Json -Method Post -Uri "$BaseUrl/api/receive-inventory" -Body @{
        vendorId = $vendor.id
        receiptDate = "2026-04-22"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                description = $item.name
                quantity = 3
                unitCost = 10
            }
        )
    }

    $afterReceiptItem = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"

    Write-Step "Creating bill against the posted receipt."
    $bill = Invoke-Json -Method Post -Uri "$BaseUrl/api/purchase-bills" -Body @{
        vendorId = $vendor.id
        inventoryReceiptId = $receipt.id
        billDate = "2026-04-22"
        dueDate = "2026-05-22"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                inventoryReceiptLineId = $receipt.lines[0].id
                description = $item.name
                quantity = 3
                unitCost = 11
            }
        )
    }

    $afterBillVendor = Invoke-Json -Method Get -Uri "$BaseUrl/api/vendors/$($vendor.id)"
    $afterBillItem = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    $transactions = Invoke-Json -Method Get -Uri "$BaseUrl/api/transactions?sourceEntityType=PurchaseBill&sourceEntityId=$($bill.id)&page=1&pageSize=20"

    Assert-True ($bill.inventoryReceiptId -eq $receipt.id) "Purchase bill was not linked to the inventory receipt."
    Assert-True ($bill.status -eq 2) "Purchase bill was not posted."
    Assert-True (($afterReceiptItem.quantityOnHand - $beforeItem.quantityOnHand) -eq 3) "Inventory receipt did not increase stock."
    Assert-True (($afterBillItem.quantityOnHand - $afterReceiptItem.quantityOnHand) -eq 0) "Purchase bill against receipt changed stock, but it should only clear GRNI."
    Assert-True (($afterBillVendor.balance - $beforeVendor.balance) -eq $bill.totalAmount) "Vendor balance did not increase by the purchase bill total."
    Assert-True ($transactions.totalCount -eq 1) "Expected one purchase bill transaction."

    [pscustomobject]@{
        receiptNumber = $receipt.receiptNumber
        billNumber = $bill.billNumber
        stockChangeOnReceipt = $afterReceiptItem.quantityOnHand - $beforeItem.quantityOnHand
        stockChangeOnBill = $afterBillItem.quantityOnHand - $afterReceiptItem.quantityOnHand
        vendorBalanceIncrease = $afterBillVendor.balance - $beforeVendor.balance
        transactionCount = $transactions.totalCount
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
