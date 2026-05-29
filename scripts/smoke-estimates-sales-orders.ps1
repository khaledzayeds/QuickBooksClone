param(
    [int]$Port = 5093,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[estimate-sales-order-smoke] $Message"
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
            Invoke-Json -Method Get -Uri "$BaseUrl/api/health" | Out-Null
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
    $startInfo.Arguments = "Zayed.Api\bin\Debug\net10.0\Zayed.Api.dll"
    $startInfo.WorkingDirectory = $RepositoryRoot
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $false
    $startInfo.RedirectStandardError = $false
    $startInfo.Environment["ASPNETCORE_URLS"] = $BaseUrl
    $startInfo.Environment["ASPNETCORE_ENVIRONMENT"] = "Development"
    $startInfo.Environment["Database__Provider"] = "Sqlite"
    $startInfo.Environment["Database__SeedDemoData"] = "true"
    $startInfo.Environment["ConnectionStrings__Zayed"] = "Data Source=$DatabasePath"
    $startInfo.Environment["Logging__LogLevel__Default"] = "Warning"
    $startInfo.Environment["Logging__LogLevel__Microsoft.AspNetCore"] = "Warning"

    $process = [System.Diagnostics.Process]::Start($startInfo)
    try {
        Wait-ForApi -BaseUrl $BaseUrl
        Initialize-SmokeCompanyRuntime -BaseUrl $BaseUrl -DatabasePath $DatabasePath
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
$SmokeCompanyRuntimeScript = Join-Path $PSScriptRoot "smoke-company-runtime.ps1"
. $SmokeCompanyRuntimeScript
$BaseUrl = "http://localhost:$Port"
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\estimates-sales-orders"
$DatabasePath = Join-Path $SmokeRoot "zayed-estimates-sales-orders-smoke.db"

New-Item -ItemType Directory -Force -Path $SmokeRoot | Out-Null
Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue

Write-Step "Building API."
dotnet build "$RepositoryRoot\Zayed.Api\Zayed.Api.csproj" --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q

$api = $null
try {
    Write-Step "Starting API on $BaseUrl with temporary SQLite database."
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath

    $customer = (Invoke-Json -Method Get -Uri "$BaseUrl/api/customers?includeInactive=false&page=1&pageSize=10").items[0]
    $item = (Invoke-Json -Method Get -Uri "$BaseUrl/api/items?includeInactive=false&page=1&pageSize=10").items[0]

    Assert-True ($null -ne $customer) "Expected a seeded smoke customer."
    Assert-True ($null -ne $item) "Expected a seeded smoke item."

    $estimate = Invoke-Json -Method Post -Uri "$BaseUrl/api/estimates" -Body @{
        customerId = $customer.id
        estimateDate = "2026-04-23"
        expirationDate = "2026-05-07"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                description = "Verification estimate line"
                quantity = 2
                unitPrice = 750
            }
        )
    }

    $salesOrder = Invoke-Json -Method Post -Uri "$BaseUrl/api/sales-orders" -Body @{
        customerId = $customer.id
        orderDate = "2026-04-23"
        expectedDate = "2026-04-30"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                description = "Verification sales order line"
                quantity = 3
                unitPrice = 725
            }
        )
    }

    Assert-True (-not [string]::IsNullOrWhiteSpace($estimate.estimateNumber)) "Estimate did not get a document number."
    Assert-True (-not [string]::IsNullOrWhiteSpace($salesOrder.orderNumber)) "Sales order did not get a document number."

    [pscustomobject]@{
        estimateNo = $estimate.estimateNumber
        estimateStatus = $estimate.status
        salesOrderNo = $salesOrder.orderNumber
        salesOrderStatus = $salesOrder.status
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
