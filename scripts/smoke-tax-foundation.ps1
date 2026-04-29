param(
    [int]$Port = 5089,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[tax-smoke] $Message"
}

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

    $json = $Body | ConvertTo-Json -Depth 10
    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -ContentType "application/json" -Body $json -TimeoutSec 30
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
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw $Message
    }
}

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$BaseUrl = "http://localhost:$Port"
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\tax-foundation"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-tax-foundation.db"

New-Item -ItemType Directory -Force -Path $SmokeRoot | Out-Null
Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue

Write-Step "Building API."
dotnet build "$RepositoryRoot\QuickBooksClone.Api\QuickBooksClone.Api.csproj" --no-restore /nr:false /m:1 /p:UseSharedCompilation=false /p:RunAnalyzers=false -v:q
if ($LASTEXITCODE -ne 0) {
    throw "Build failed."
}

$api = $null
try {
    Write-Step "Starting API on $BaseUrl with temporary SQLite database."
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath

    $login = Invoke-Json -Method Post -Uri "$BaseUrl/api/auth/login" -Body @{
        userName = "admin"
        password = "admin"
    }
    Assert-True (-not [string]::IsNullOrWhiteSpace($login.token)) "Expected admin token."

    $taxCodes = Invoke-Json -Method Get -Uri "$BaseUrl/api/tax-codes?pageSize=20" -Token $login.token
    $salesTaxCode = $taxCodes.items | Where-Object { $_.code -eq "VAT14-S" } | Select-Object -First 1
    Assert-True ($null -ne $salesTaxCode) "Expected seeded sales VAT code."

    $settings = Invoke-Json -Method Get -Uri "$BaseUrl/api/settings/company" -Token $login.token
    $updatedSettings = Invoke-Json -Method Put -Uri "$BaseUrl/api/settings/company" -Token $login.token -Body @{
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
        defaultPurchaseTaxCodeId = $settings.defaultPurchaseTaxCodeId
        pricesIncludeTax = $false
        taxRoundingMode = 1
        defaultSalesTaxPayableAccountId = $settings.defaultSalesTaxPayableAccountId
        defaultPurchaseTaxReceivableAccountId = $settings.defaultPurchaseTaxReceivableAccountId
    }
    Assert-True ($updatedSettings.taxesEnabled -eq $true) "Expected taxes to be enabled."

    $customers = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers?pageSize=1" -Token $login.token
    $items = Invoke-Json -Method Get -Uri "$BaseUrl/api/items?search=Setup&pageSize=5" -Token $login.token
    $customer = $customers.items | Select-Object -First 1
    $item = $items.items | Where-Object { $_.name -eq "Setup Fee" } | Select-Object -First 1
    Assert-True ($null -ne $customer) "Expected seeded customer."
    Assert-True ($null -ne $item) "Expected seeded non-inventory item."

    $invoice = Invoke-Json -Method Post -Uri "$BaseUrl/api/invoices" -Token $login.token -Body @{
        customerId = $customer.id
        invoiceDate = "2026-04-29"
        dueDate = "2026-04-29"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                description = "Tax smoke line"
                quantity = 1
                unitPrice = 100
                discountPercent = 0
                taxCodeId = $salesTaxCode.id
            }
        )
    }

    Assert-True ([decimal]$invoice.taxAmount -eq 14) "Expected invoice tax amount to be 14."
    Assert-True ([decimal]$invoice.totalAmount -eq 114) "Expected invoice total amount to be 114."

    $transactions = Invoke-Json -Method Get -Uri "$BaseUrl/api/transactions?sourceEntityType=Invoice&sourceEntityId=$($invoice.id)&pageSize=5" -Token $login.token
    $transaction = $transactions.items | Select-Object -First 1
    Assert-True ($null -ne $transaction) "Expected posted invoice transaction."

    $taxLine = $transaction.lines | Where-Object { $_.accountName -eq "Sales Tax Payable" -and [decimal]$_.credit -eq 14 } | Select-Object -First 1
    Assert-True ($null -ne $taxLine) "Expected Sales Tax Payable credit line."

    [pscustomobject]@{
        invoiceNumber = $invoice.invoiceNumber
        taxAmount = $invoice.taxAmount
        totalAmount = $invoice.totalAmount
        taxAccountCredited = $taxLine.accountName
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
