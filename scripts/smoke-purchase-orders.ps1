param(
    [int]$Port = 5076,
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
            Invoke-Json -Method Get -Uri "$BaseUrl/api/vendors?pageSize=1" | Out-Null
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
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\purchase-orders"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-purchase-orders.db"

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

    $vendors = Invoke-Json -Method Get -Uri "$BaseUrl/api/vendors?pageSize=10"
    $items = Invoke-Json -Method Get -Uri "$BaseUrl/api/items?pageSize=10"
    $vendor = $vendors.items | Select-Object -First 1
    $item = $items.items | Select-Object -First 1

    Assert-True ($null -ne $vendor) "Expected at least one seeded vendor."
    Assert-True ($null -ne $item) "Expected at least one seeded item."

    $itemBefore = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"

    Write-Step "Creating draft purchase order without accounting or inventory effect."
    $draftOrder = Invoke-Json -Method Post -Uri "$BaseUrl/api/purchase-orders" -Body @{
        vendorId = $vendor.id
        orderDate = "2026-04-19"
        expectedDate = "2026-04-26"
        saveMode = 1
        lines = @(
            @{
                itemId = $item.id
                description = "Draft PO smoke"
                quantity = 3
                unitCost = 25
            }
        )
    }

    Assert-True ($draftOrder.status -eq 1) "Draft purchase order was not saved as Draft."
    Assert-True ($draftOrder.totalAmount -eq 75) "Draft purchase order total is incorrect."

    $draftTransactions = Invoke-Json -Method Get -Uri "$BaseUrl/api/transactions?sourceEntityType=PurchaseOrder&sourceEntityId=$($draftOrder.id)&pageSize=25"
    Assert-True ($draftTransactions.totalCount -eq 0) "Purchase order should not create accounting transactions."

    $itemAfterDraft = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    Assert-True ($itemAfterDraft.quantityOnHand -eq $itemBefore.quantityOnHand) "Purchase order should not change inventory quantity."

    Write-Step "Opening and closing the purchase order."
    $openedOrder = Invoke-Json -Method Post -Uri "$BaseUrl/api/purchase-orders/$($draftOrder.id)/open"
    Assert-True ($openedOrder.status -eq 2) "Purchase order did not move to Open."

    $closedOrder = Invoke-Json -Method Post -Uri "$BaseUrl/api/purchase-orders/$($draftOrder.id)/close"
    Assert-True ($closedOrder.status -eq 3) "Purchase order did not move to Closed."

    Write-Step "Creating a second purchase order directly as open."
    $openOrder = Invoke-Json -Method Post -Uri "$BaseUrl/api/purchase-orders" -Body @{
        vendorId = $vendor.id
        orderDate = "2026-04-19"
        expectedDate = "2026-04-28"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                description = "Open PO smoke"
                quantity = 2
                unitCost = 30
            }
        )
    }

    Assert-True ($openOrder.status -eq 2) "SaveAsOpen purchase order was not opened."

    $searchDefault = Invoke-Json -Method Get -Uri "$BaseUrl/api/purchase-orders?pageSize=50"
    $searchWithClosed = Invoke-Json -Method Get -Uri "$BaseUrl/api/purchase-orders?includeClosed=true&pageSize=50"

    $defaultMatches = @($searchDefault.items | Where-Object { $_.id -eq $closedOrder.id })
    $closedMatches = @($searchWithClosed.items | Where-Object { $_.id -eq $closedOrder.id })

    Assert-True ($defaultMatches.Count -eq 0) "Closed purchase order should be hidden by default search."
    Assert-True ($closedMatches.Count -eq 1) "Closed purchase order should appear when includeClosed=true."

    $vendorAfter = Invoke-Json -Method Get -Uri "$BaseUrl/api/vendors/$($vendor.id)"
    $itemAfter = Invoke-Json -Method Get -Uri "$BaseUrl/api/items/$($item.id)"
    $transactionsAfter = Invoke-Json -Method Get -Uri "$BaseUrl/api/transactions?sourceEntityType=PurchaseOrder&pageSize=25"

    Assert-True ($vendorAfter.balance -eq $vendor.balance) "Purchase order should not change vendor balance."
    Assert-True ($itemAfter.quantityOnHand -eq $itemBefore.quantityOnHand) "Purchase order should not change inventory quantity after open/close."
    Assert-True ($transactionsAfter.totalCount -eq 0) "Purchase order workflow should still have zero accounting transactions."

    [pscustomobject]@{
        draftOrderNumber = $draftOrder.orderNumber
        closedOrderStatus = $closedOrder.status
        openOrderStatus = $openOrder.status
        vendorBalanceUnchanged = ($vendorAfter.balance -eq $vendor.balance)
        inventoryUnchanged = ($itemAfter.quantityOnHand -eq $itemBefore.quantityOnHand)
        transactionCount = $transactionsAfter.totalCount
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
