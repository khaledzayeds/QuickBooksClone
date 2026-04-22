param(
    [int]$Port = 5088,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[receive-smoke] $Message"
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
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\receive-inventory"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-receive-smoke.db"

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

    Write-Step "Creating open purchase order for later receiving."
    $order = Invoke-Json -Method Post -Uri "$BaseUrl/api/purchase-orders" -Body @{
        vendorId = $vendor.id
        orderDate = "2026-04-22"
        expectedDate = "2026-04-25"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                description = $item.name
                quantity = 4
                unitCost = 9.5
            }
        )
    }

    $orderLine = $order.lines[0]

    Write-Step "Receiving inventory against the purchase order."
    $receipt = Invoke-Json -Method Post -Uri "$BaseUrl/api/receive-inventory" -Body @{
        vendorId = $vendor.id
        purchaseOrderId = $order.id
        receiptDate = "2026-04-22"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                purchaseOrderLineId = $orderLine.id
                description = $item.name
                quantity = 4
                unitCost = 9.5
            }
        )
    }

    $afterVendor = Invoke-Json -Method Get -Uri "$BaseUrl/api/vendors/$($vendor.id)"
    $afterItem = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    $receipts = Invoke-Json -Method Get -Uri "$BaseUrl/api/receive-inventory?purchaseOrderId=$($order.id)&page=1&pageSize=20"
    $transactions = Invoke-Json -Method Get -Uri "$BaseUrl/api/transactions?sourceEntityType=InventoryReceipt&sourceEntityId=$($receipt.id)&page=1&pageSize=20"

    Assert-True ($receipt.receiptNumber -eq "DEV01-2026-00002" -or $receipt.receiptNumber -like "DEV01-2026-*") "Inventory receipt did not get a sync-ready document number."
    Assert-True ($receipt.status -eq 2) "Inventory receipt was not posted."
    Assert-True (($afterItem.quantityOnHand - $beforeItem.quantityOnHand) -eq 4) "Inventory quantity did not increase by the received amount."
    Assert-True ($afterVendor.balance -eq $beforeVendor.balance) "Vendor balance changed during receive inventory, but it should remain unchanged until billing."
    Assert-True ($transactions.totalCount -eq 1) "Expected one inventory receipt transaction."
    Assert-True ($receipts.totalCount -ge 1) "Expected the new inventory receipt to be searchable."

    [pscustomobject]@{
        purchaseOrderNumber = $order.orderNumber
        receiptNumber = $receipt.receiptNumber
        receiptStatus = $receipt.status
        quantityReceived = $afterItem.quantityOnHand - $beforeItem.quantityOnHand
        vendorBalanceUnchanged = ($afterVendor.balance -eq $beforeVendor.balance)
        transactionCount = $transactions.totalCount
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
