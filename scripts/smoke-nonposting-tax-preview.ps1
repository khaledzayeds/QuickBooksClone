param(
    [int]$Port = 5117,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step { param([string]$Message) Write-Host "[nonposting-tax-smoke] $Message" }
function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw $Message } }

function Invoke-Json {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [object]$Body = $null,
        [string]$Token = $null
    )

    $headers = @{}
    if (-not [string]::IsNullOrWhiteSpace($Token)) {
        $headers["Authorization"] = "Bearer $Token"
    }

    if ($null -eq $Body) {
        return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -TimeoutSec 30
    }

    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -ContentType "application/json" -Body ($Body | ConvertTo-Json -Depth 10) -TimeoutSec 30
}

function Wait-ForApi {
    param([Parameter(Mandatory = $true)][string]$BaseUrl)
    for ($i = 0; $i -lt 120; $i++) {
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
    param([Parameter(Mandatory = $true)][string]$BaseUrl, [Parameter(Mandatory = $true)][string]$DatabasePath)

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
    if ($null -ne $Process -and -not $Process.HasExited) {
        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
        $Process.WaitForExit()
    }
}

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$BaseUrl = "http://localhost:$Port"
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\nonposting-tax-preview"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-nonposting-tax-preview.db"

New-Item -ItemType Directory -Force -Path $SmokeRoot | Out-Null
Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue

Write-Step "Building API."
dotnet build "$RepositoryRoot\QuickBooksClone.Api\QuickBooksClone.Api.csproj" --no-restore /nr:false /m:1 /p:UseSharedCompilation=false /p:RunAnalyzers=false -v:q
if ($LASTEXITCODE -ne 0) { throw "Build failed." }

$api = $null
try {
    Write-Step "Starting API on $BaseUrl with temporary SQLite database."
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath

    $login = Invoke-Json -Method Post -Uri "$BaseUrl/api/auth/login" -Body @{ userName = "admin"; password = "admin" }
    $token = $login.token
    Assert-True (-not [string]::IsNullOrWhiteSpace($token)) "Expected admin token."

    $taxCodes = Invoke-Json -Method Get -Uri "$BaseUrl/api/tax-codes?pageSize=20" -Token $token
    $salesTaxCode = $taxCodes.items | Where-Object { $_.code -eq "VAT14-S" } | Select-Object -First 1
    $purchaseTaxCode = $taxCodes.items | Where-Object { $_.code -eq "VAT14-P" } | Select-Object -First 1
    Assert-True ($null -ne $salesTaxCode) "Expected seeded sales tax code."
    Assert-True ($null -ne $purchaseTaxCode) "Expected seeded purchase tax code."

    $settings = Invoke-Json -Method Get -Uri "$BaseUrl/api/settings/company" -Token $token
    Invoke-Json -Method Put -Uri "$BaseUrl/api/settings/company" -Token $token -Body @{
        companyName = $settings.companyName
        legalName = $settings.legalName
        email = $settings.email
        phone = $settings.phone
        currency = $settings.currency
        country = $settings.country
        timeZoneId = $settings.timeZoneId
        defaultLanguage = $settings.defaultLanguage
        taxRegistrationNumber = $settings.taxRegistrationNumber
        addressLine1 = $settings.addressLine1
        addressLine2 = $settings.addressLine2
        city = $settings.city
        region = $settings.region
        postalCode = $settings.postalCode
        fiscalYearStartMonth = $settings.fiscalYearStartMonth
        fiscalYearStartDay = $settings.fiscalYearStartDay
        defaultSalesTaxRate = $settings.defaultSalesTaxRate
        defaultPurchaseTaxRate = $settings.defaultPurchaseTaxRate
        taxesEnabled = $true
        defaultSalesTaxCodeId = $salesTaxCode.id
        defaultPurchaseTaxCodeId = $purchaseTaxCode.id
        pricesIncludeTax = $false
        taxRoundingMode = 1
        defaultSalesTaxPayableAccountId = $settings.defaultSalesTaxPayableAccountId
        defaultPurchaseTaxReceivableAccountId = $settings.defaultPurchaseTaxReceivableAccountId
    } | Out-Null

    $customers = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers?pageSize=1" -Token $token
    $vendors = Invoke-Json -Method Get -Uri "$BaseUrl/api/vendors?pageSize=1" -Token $token
    $items = Invoke-Json -Method Get -Uri "$BaseUrl/api/items?search=Setup&pageSize=5" -Token $token
    $customer = $customers.items | Select-Object -First 1
    $vendor = $vendors.items | Select-Object -First 1
    $item = $items.items | Where-Object { $_.name -eq "Setup Fee" } | Select-Object -First 1
    Assert-True ($null -ne $customer) "Expected seeded customer."
    Assert-True ($null -ne $vendor) "Expected seeded vendor."
    Assert-True ($null -ne $item) "Expected seeded item."

    $estimate = Invoke-Json -Method Post -Uri "$BaseUrl/api/estimates" -Token $token -Body @{
        customerId = $customer.id
        estimateDate = "2026-04-29"
        expirationDate = "2026-05-29"
        saveMode = 2
        lines = @(@{ itemId = $item.id; description = "Tax estimate"; quantity = 2; unitPrice = 100; taxCodeId = $salesTaxCode.id })
    }
    Assert-True ([decimal]$estimate.subtotal -eq 200) "Expected estimate subtotal 200."
    Assert-True ([decimal]$estimate.taxAmount -eq 28) "Expected estimate tax 28."
    Assert-True ([decimal]$estimate.totalAmount -eq 228) "Expected estimate total 228."

    $salesOrder = Invoke-Json -Method Post -Uri "$BaseUrl/api/estimates/$($estimate.id)/convert-to-sales-order" -Token $token -Body @{
        orderDate = "2026-04-29"
        expectedDate = "2026-05-05"
        saveMode = 2
        lines = @()
    }
    Assert-True ([decimal]$salesOrder.taxAmount -eq 28) "Expected converted sales order tax 28."

    $invoice = Invoke-Json -Method Post -Uri "$BaseUrl/api/sales-orders/$($salesOrder.id)/convert-to-invoice" -Token $token -Body @{
        invoiceDate = "2026-04-29"
        dueDate = "2026-05-29"
        saveMode = 1
        lines = @()
    }
    Assert-True ([decimal]$invoice.taxAmount -eq 28) "Expected converted invoice tax 28."

    $purchaseOrder = Invoke-Json -Method Post -Uri "$BaseUrl/api/purchase-orders" -Token $token -Body @{
        vendorId = $vendor.id
        orderDate = "2026-04-29"
        expectedDate = "2026-05-05"
        saveMode = 2
        lines = @(@{ itemId = $item.id; description = "Tax PO"; quantity = 1; unitCost = 50; taxCodeId = $purchaseTaxCode.id })
    }
    Assert-True ([decimal]$purchaseOrder.subtotal -eq 50) "Expected purchase order subtotal 50."
    Assert-True ([decimal]$purchaseOrder.taxAmount -eq 7) "Expected purchase order tax 7."
    Assert-True ([decimal]$purchaseOrder.totalAmount -eq 57) "Expected purchase order total 57."

    [pscustomobject]@{
        estimateTax = $estimate.taxAmount
        salesOrderTax = $salesOrder.taxAmount
        invoiceTax = $invoice.taxAmount
        purchaseOrderTax = $purchaseOrder.taxAmount
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api
    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
