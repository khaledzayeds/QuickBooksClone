param(
    [int]$Port = 5090,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[purchase-workflow-smoke] $Message"
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
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\purchase-workflow-plans"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-purchase-workflow-smoke.db"

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

    Write-Step "Creating open purchase order."
    $order = Invoke-Json -Method Post -Uri "$BaseUrl/api/purchase-orders" -Body @{
        vendorId = $vendor.id
        orderDate = "2026-04-23"
        expectedDate = "2026-04-30"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                description = $item.name
                quantity = 5
                unitCost = 10
            }
        )
    }

    Write-Step "Validating initial receiving plan."
    $initialReceivingPlan = Invoke-Json -Method Get -Uri "$BaseUrl/api/purchase-orders/$($order.id)/receiving-plan"
    Assert-True ($initialReceivingPlan.canReceive -eq $true) "Initial receiving plan should allow receiving."
    Assert-True ($initialReceivingPlan.totalOrderedQuantity -eq 5) "Initial ordered quantity should be 5."
    Assert-True ($initialReceivingPlan.totalReceivedQuantity -eq 0) "Initial received quantity should be 0."
    Assert-True ($initialReceivingPlan.totalRemainingQuantity -eq 5) "Initial remaining quantity should be 5."
    Assert-True ($initialReceivingPlan.linkedReceipts.Count -eq 0) "No linked receipts should exist before receiving."
    Assert-True ($initialReceivingPlan.lines[0].suggestedReceiveQuantity -eq 5) "Suggested receive quantity should match remaining quantity."

    Write-Step "Creating partial inventory receipt from purchase order."
    $receipt = Invoke-Json -Method Post -Uri "$BaseUrl/api/receive-inventory" -Body @{
        vendorId = $vendor.id
        receiptDate = "2026-04-23"
        purchaseOrderId = $order.id
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                purchaseOrderLineId = $order.lines[0].id
                description = $item.name
                quantity = 2
                unitCost = 10
            }
        )
    }

    Write-Step "Validating receiving plan after partial receipt."
    $receivingPlan = Invoke-Json -Method Get -Uri "$BaseUrl/api/purchase-orders/$($order.id)/receiving-plan"
    Assert-True ($receivingPlan.totalReceivedQuantity -eq 2) "Receiving plan should report 2 received units."
    Assert-True ($receivingPlan.totalRemainingQuantity -eq 3) "Receiving plan should report 3 remaining units."
    Assert-True ($receivingPlan.canReceive -eq $true) "Purchase order should still be receivable after partial receipt."
    Assert-True ($receivingPlan.isFullyReceived -eq $false) "Purchase order should not be fully received after partial receipt."
    Assert-True ($receivingPlan.linkedReceipts.Count -eq 1) "Receiving plan should include the linked receipt."
    Assert-True ($receivingPlan.linkedReceipts[0].id -eq $receipt.id) "Receiving plan linked receipt id mismatch."
    Assert-True ($receivingPlan.lines[0].receivedQuantity -eq 2) "Receiving plan line should report the partial receipt quantity."
    Assert-True ($receivingPlan.lines[0].remainingQuantity -eq 3) "Receiving plan line should report the remaining quantity."
    Assert-True ($receivingPlan.lines[0].suggestedReceiveQuantity -eq 3) "Receiving plan line should suggest the remaining quantity."

    Write-Step "Validating initial billing plan for the receipt."
    $initialBillingPlan = Invoke-Json -Method Get -Uri "$BaseUrl/api/receive-inventory/$($receipt.id)/billing-plan"
    Assert-True ($initialBillingPlan.purchaseOrderId -eq $order.id) "Billing plan should keep the source purchase order link."
    Assert-True ($initialBillingPlan.canBill -eq $true) "Receipt should be billable before billing."
    Assert-True ($initialBillingPlan.totalReceivedQuantity -eq 2) "Billing plan should report the received quantity."
    Assert-True ($initialBillingPlan.totalBilledQuantity -eq 0) "Billing plan should report 0 billed quantity initially."
    Assert-True ($initialBillingPlan.totalRemainingQuantity -eq 2) "Billing plan should report the full received quantity as remaining."
    Assert-True ($initialBillingPlan.linkedBills.Count -eq 0) "No linked bills should exist before billing."
    Assert-True ($initialBillingPlan.lines[0].suggestedBillQuantity -eq 2) "Suggested bill quantity should match remaining quantity."

    Write-Step "Creating partial purchase bill from receipt."
    $bill = Invoke-Json -Method Post -Uri "$BaseUrl/api/purchase-bills" -Body @{
        vendorId = $vendor.id
        inventoryReceiptId = $receipt.id
        billDate = "2026-04-23"
        dueDate = "2026-05-23"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                inventoryReceiptLineId = $receipt.lines[0].id
                description = $item.name
                quantity = 1
                unitCost = 10
            }
        )
    }

    Write-Step "Validating billing plan after partial bill."
    $billingPlan = Invoke-Json -Method Get -Uri "$BaseUrl/api/receive-inventory/$($receipt.id)/billing-plan"
    Assert-True ($billingPlan.totalBilledQuantity -eq 1) "Billing plan should report the billed quantity."
    Assert-True ($billingPlan.totalRemainingQuantity -eq 1) "Billing plan should report the remaining billable quantity."
    Assert-True ($billingPlan.canBill -eq $true) "Receipt should still be billable after a partial bill."
    Assert-True ($billingPlan.isFullyBilled -eq $false) "Receipt should not be fully billed after a partial bill."
    Assert-True ($billingPlan.linkedBills.Count -eq 1) "Billing plan should include the linked bill."
    Assert-True ($billingPlan.linkedBills[0].id -eq $bill.id) "Billing plan linked bill id mismatch."
    Assert-True ($billingPlan.lines[0].billedQuantity -eq 1) "Billing plan line should report billed quantity."
    Assert-True ($billingPlan.lines[0].remainingQuantity -eq 1) "Billing plan line should report remaining quantity."
    Assert-True ($billingPlan.lines[0].suggestedBillQuantity -eq 1) "Billing plan line should suggest the remaining quantity."

    [pscustomobject]@{
        purchaseOrderNumber = $order.orderNumber
        receiptNumber = $receipt.receiptNumber
        billNumber = $bill.billNumber
        poRemainingAfterReceipt = $receivingPlan.totalRemainingQuantity
        receiptRemainingAfterBill = $billingPlan.totalRemainingQuantity
        linkedReceiptCount = $receivingPlan.linkedReceipts.Count
        linkedBillCount = $billingPlan.linkedBills.Count
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
