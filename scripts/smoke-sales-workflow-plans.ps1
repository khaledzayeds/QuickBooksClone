param(
    [int]$Port = 5091,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[sales-workflow-smoke] $Message"
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
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\sales-workflow-plans"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-sales-workflow-smoke.db"

New-Item -ItemType Directory -Force -Path $SmokeRoot | Out-Null
Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue

Write-Step "Building API."
dotnet build "$RepositoryRoot\QuickBooksClone.Api\QuickBooksClone.Api.csproj" --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q

$api = $null
try {
    Write-Step "Starting API on $BaseUrl with temporary SQLite database."
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath

    $customers = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers?page=1&pageSize=10"
    $items = Invoke-Json -Method Get -Uri "$BaseUrl/api/items?page=1&pageSize=20"
    $accounts = Invoke-Json -Method Get -Uri "$BaseUrl/api/accounts?page=1&pageSize=50&includeInactive=true"

    $customer = $customers.items[0]
    $item = ($items.items | Where-Object { $_.itemType -eq 2 -or $_.itemType -eq 3 })[0]
    $cashAccount = ($accounts.items | Where-Object { $_.code -eq '1000' })[0]

    Write-Step "Creating sent estimate."
    $estimate = Invoke-Json -Method Post -Uri "$BaseUrl/api/estimates" -Body @{
        customerId = $customer.id
        estimateDate = "2026-04-23"
        expirationDate = "2026-05-23"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                description = $item.name
                quantity = 5
                unitPrice = 750
            }
        )
    }

    Write-Step "Validating initial estimate -> sales-order plan."
    $estimatePlanBefore = Invoke-Json -Method Get -Uri "$BaseUrl/api/estimates/$($estimate.id)/sales-order-plan"
    Assert-True ($estimatePlanBefore.canConvert -eq $true) "Estimate should be convertible."
    Assert-True ($estimatePlanBefore.totalEstimatedQuantity -eq 5) "Estimate planned quantity mismatch."
    Assert-True ($estimatePlanBefore.totalOrderedQuantity -eq 0) "No sales-order quantity should exist yet."
    Assert-True ($estimatePlanBefore.totalRemainingQuantity -eq 5) "Initial estimate remaining quantity should be 5."

    Write-Step "Converting partial estimate quantity into an open sales order."
    $salesOrder = Invoke-Json -Method Post -Uri "$BaseUrl/api/estimates/$($estimate.id)/convert-to-sales-order" -Body @{
        orderDate = "2026-04-23"
        expectedDate = "2026-04-30"
        saveMode = 2
        lines = @(
            @{
                estimateLineId = $estimate.lines[0].id
                quantity = 3
            }
        )
    }

    Assert-True ($salesOrder.estimateId -eq $estimate.id) "Sales order should keep the source estimate link."
    Assert-True ($salesOrder.lines[0].estimateLineId -eq $estimate.lines[0].id) "Sales order line should keep the source estimate-line link."

    $estimateAfterConvert = Invoke-Json -Method Get -Uri "$BaseUrl/api/estimates/$($estimate.id)"
    $estimatePlanAfter = Invoke-Json -Method Get -Uri "$BaseUrl/api/estimates/$($estimate.id)/sales-order-plan"
    Assert-True ($estimateAfterConvert.status -eq 3) "Estimate should be accepted after conversion to an open sales order."
    Assert-True ($estimatePlanAfter.totalOrderedQuantity -eq 3) "Estimate ordered quantity should be 3 after conversion."
    Assert-True ($estimatePlanAfter.totalRemainingQuantity -eq 2) "Estimate remaining quantity should be 2 after conversion."
    Assert-True ($estimatePlanAfter.linkedSalesOrders.Count -eq 1) "Estimate plan should include the linked sales order."

    Write-Step "Validating initial sales-order -> invoice plan."
    $invoicePlanBefore = Invoke-Json -Method Get -Uri "$BaseUrl/api/sales-orders/$($salesOrder.id)/invoice-plan"
    Assert-True ($invoicePlanBefore.canConvert -eq $true) "Sales order should be convertible to invoice."
    Assert-True ($invoicePlanBefore.totalOrderedQuantity -eq 3) "Sales-order planned quantity mismatch."
    Assert-True ($invoicePlanBefore.totalInvoicedQuantity -eq 0) "No invoiced quantity should exist yet."
    Assert-True ($invoicePlanBefore.totalRemainingQuantity -eq 3) "Initial sales-order remaining quantity should be 3."

    Write-Step "Converting partial sales order quantity into a posted invoice."
    $invoice1 = Invoke-Json -Method Post -Uri "$BaseUrl/api/sales-orders/$($salesOrder.id)/convert-to-invoice" -Body @{
        invoiceDate = "2026-04-23"
        dueDate = "2026-05-23"
        saveMode = 2
        lines = @(
            @{
                salesOrderLineId = $salesOrder.lines[0].id
                quantity = 2
                discountPercent = 0
            }
        )
    }

    Assert-True ($invoice1.salesOrderId -eq $salesOrder.id) "Invoice should keep the source sales-order link."
    Assert-True ($invoice1.lines[0].salesOrderLineId -eq $salesOrder.lines[0].id) "Invoice line should keep the source sales-order-line link."
    Assert-True ($invoice1.status -eq 6) "Converted invoice should be posted."

    $invoicePlanAfterFirst = Invoke-Json -Method Get -Uri "$BaseUrl/api/sales-orders/$($salesOrder.id)/invoice-plan"
    Assert-True ($invoicePlanAfterFirst.totalInvoicedQuantity -eq 2) "Invoiced quantity should be 2 after first invoice."
    Assert-True ($invoicePlanAfterFirst.totalRemainingQuantity -eq 1) "Remaining quantity should be 1 after first invoice."
    Assert-True ($invoicePlanAfterFirst.linkedInvoices.Count -eq 1) "Invoice plan should include the first linked invoice."

    Write-Step "Validating invoice payment plan."
    $paymentPlanBefore = Invoke-Json -Method Get -Uri "$BaseUrl/api/invoices/$($invoice1.id)/payment-plan"
    Assert-True ($paymentPlanBefore.canReceivePayment -eq $true) "Posted invoice should allow receiving payment."
    Assert-True ($paymentPlanBefore.balanceDue -eq $invoice1.balanceDue) "Payment plan should expose the live invoice balance."
    Assert-True ($paymentPlanBefore.linkedPayments.Count -eq 0) "No linked payments should exist before payment."

    Write-Step "Receiving payment for the invoice."
    $payment = Invoke-Json -Method Post -Uri "$BaseUrl/api/payments" -Body @{
        invoiceId = $invoice1.id
        depositAccountId = $cashAccount.id
        paymentDate = "2026-04-23"
        amount = $invoice1.balanceDue
        paymentMethod = "Cash"
    }

    $paymentPlanAfter = Invoke-Json -Method Get -Uri "$BaseUrl/api/invoices/$($invoice1.id)/payment-plan"
    Assert-True ($paymentPlanAfter.isFullyPaid -eq $true) "Invoice payment plan should report the invoice as fully paid."
    Assert-True ($paymentPlanAfter.balanceDue -eq 0) "Invoice balance should be zero after full payment."
    Assert-True ($paymentPlanAfter.linkedPayments.Count -eq 1) "Payment plan should include the linked payment."
    Assert-True ($paymentPlanAfter.linkedPayments[0].id -eq $payment.id) "Payment plan linked payment id mismatch."

    Write-Step "Creating second invoice for the remaining sales-order quantity."
    $invoice2 = Invoke-Json -Method Post -Uri "$BaseUrl/api/sales-orders/$($salesOrder.id)/convert-to-invoice" -Body @{
        invoiceDate = "2026-04-24"
        dueDate = "2026-05-24"
        saveMode = 2
        lines = @(
            @{
                salesOrderLineId = $salesOrder.lines[0].id
                quantity = 1
                discountPercent = 0
            }
        )
    }

    $invoicePlanAfterSecond = Invoke-Json -Method Get -Uri "$BaseUrl/api/sales-orders/$($salesOrder.id)/invoice-plan"
    $salesOrderAfter = Invoke-Json -Method Get -Uri "$BaseUrl/api/sales-orders/$($salesOrder.id)"
    Assert-True ($invoicePlanAfterSecond.totalInvoicedQuantity -eq 3) "All sales-order quantity should be invoiced after the second invoice."
    Assert-True ($invoicePlanAfterSecond.totalRemainingQuantity -eq 0) "No sales-order quantity should remain after the second invoice."
    Assert-True ($invoicePlanAfterSecond.isFullyInvoiced -eq $true) "Sales-order plan should report full invoicing."
    Assert-True ($salesOrderAfter.status -eq 3) "Sales order should close automatically after full invoicing."

    [pscustomobject]@{
        estimateNumber = $estimate.estimateNumber
        salesOrderNumber = $salesOrder.orderNumber
        firstInvoiceNumber = $invoice1.invoiceNumber
        secondInvoiceNumber = $invoice2.invoiceNumber
        paymentNumber = $payment.paymentNumber
        estimateRemainingQuantity = $estimatePlanAfter.totalRemainingQuantity
        salesOrderRemainingQuantity = $invoicePlanAfterSecond.totalRemainingQuantity
        paymentLinkedCount = $paymentPlanAfter.linkedPayments.Count
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
