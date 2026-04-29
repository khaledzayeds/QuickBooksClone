param(
    [int]$Port = 5103,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[api-contract-smoke] $Message"
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw $Message
    }
}

function Invoke-Json {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [object]$Body = $null,
        [string]$Token = $null,
        [int]$TimeoutSec = 30
    )

    $headers = @{}
    if (-not [string]::IsNullOrWhiteSpace($Token)) {
        $headers["Authorization"] = "Bearer $Token"
    }

    if ($null -eq $Body) {
        return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -TimeoutSec $TimeoutSec
    }

    $json = $Body | ConvertTo-Json -Depth 10
    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -ContentType "application/json" -Body $json -TimeoutSec $TimeoutSec
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

function Assert-HasProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$PropertyName,
        [Parameter(Mandatory = $true)][string]$Context
    )

    $names = $Object.PSObject.Properties.Name
    Assert-True ($names -contains $PropertyName) "Expected '$Context' to include property '$PropertyName'."
}

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$BaseUrl = "http://localhost:$Port"
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\api-contract"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-api-contract.db"

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

    Write-Step "Checking OpenAPI route surface."
    $openApi = Invoke-Json -Method Get -Uri "$BaseUrl/openapi/v1.json" -TimeoutSec 180
    $paths = $openApi.paths.PSObject.Properties.Name
    $requiredPaths = @(
        "/api/settings/runtime",
        "/api/auth/login",
        "/api/accounts",
        "/api/customers",
        "/api/vendors",
        "/api/items",
        "/api/purchase-orders/{id}/receiving-plan",
        "/api/receive-inventory/{id}/billing-plan",
        "/api/purchase-bills/{id}/payment-plan",
        "/api/estimates/{id}/sales-order-plan",
        "/api/sales-orders/{id}/invoice-plan",
        "/api/invoices/{id}/payment-plan",
        "/api/tax-codes",
        "/api/reports/tax-summary",
        "/api/sync/overview",
        "/api/audit"
    )

    foreach ($path in $requiredPaths) {
        Assert-True ($paths -contains $path) "OpenAPI contract is missing path: $path"
    }

    Write-Step "Checking live runtime and authenticated DTO shape."
    $runtime = Invoke-Json -Method Get -Uri "$BaseUrl/api/settings/runtime"
    Assert-HasProperty -Object $runtime -PropertyName "databaseProvider" -Context "runtime settings"
    Assert-HasProperty -Object $runtime -PropertyName "environmentName" -Context "runtime settings"

    $login = Invoke-Json -Method Post -Uri "$BaseUrl/api/auth/login" -Body @{
        userName = "admin"
        password = "admin"
    }
    Assert-True (-not [string]::IsNullOrWhiteSpace($login.token)) "Expected admin token."
    Assert-HasProperty -Object $login -PropertyName "user" -Context "login response"
    Assert-HasProperty -Object $login.user -PropertyName "effectivePermissions" -Context "login user response"

    $settings = Invoke-Json -Method Get -Uri "$BaseUrl/api/settings/company" -Token $login.token
    Assert-HasProperty -Object $settings -PropertyName "taxesEnabled" -Context "company settings"
    Assert-HasProperty -Object $settings -PropertyName "defaultSalesTaxCodeId" -Context "company settings"
    Assert-HasProperty -Object $settings -PropertyName "pricesIncludeTax" -Context "company settings"
    Assert-HasProperty -Object $settings -PropertyName "taxRoundingMode" -Context "company settings"

    $taxCodes = Invoke-Json -Method Get -Uri "$BaseUrl/api/tax-codes?pageSize=10" -Token $login.token
    Assert-HasProperty -Object $taxCodes -PropertyName "items" -Context "tax code list"
    $firstTaxCode = $taxCodes.items | Select-Object -First 1
    Assert-True ($null -ne $firstTaxCode) "Expected seeded tax codes."
    Assert-HasProperty -Object $firstTaxCode -PropertyName "code" -Context "tax code dto"
    Assert-HasProperty -Object $firstTaxCode -PropertyName "scope" -Context "tax code dto"
    Assert-HasProperty -Object $firstTaxCode -PropertyName "ratePercent" -Context "tax code dto"
    Assert-HasProperty -Object $firstTaxCode -PropertyName "taxAccountId" -Context "tax code dto"

    $taxSummary = Invoke-Json -Method Get -Uri "$BaseUrl/api/reports/tax-summary?fromDate=2026-01-01&toDate=2026-12-31&includeZeroRows=true" -Token $login.token
    Assert-HasProperty -Object $taxSummary -PropertyName "totalOutputTax" -Context "tax summary"
    Assert-HasProperty -Object $taxSummary -PropertyName "totalInputTax" -Context "tax summary"
    Assert-HasProperty -Object $taxSummary -PropertyName "netTaxPayable" -Context "tax summary"

    [pscustomobject]@{
        openApiPathCount = $paths.Count
        checkedPaths = $requiredPaths.Count
        provider = $runtime.databaseProvider
        taxCodeCount = $taxCodes.totalCount
        taxSummaryFieldsVerified = $true
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
