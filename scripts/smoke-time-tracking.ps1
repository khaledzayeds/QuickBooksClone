param(
    [int]$Port = 5124,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[time-tracking-smoke] $Message"
}

function Invoke-Json {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [object]$Body = $null,
        [hashtable]$Headers = $null
    )

    $arguments = @{
        Method = $Method
        Uri = $Uri
        TimeoutSec = 60
    }

    if ($Headers) {
        $arguments.Headers = $Headers
    }

    if ($null -ne $Body) {
        $arguments.ContentType = "application/json"
        $arguments.Body = $Body | ConvertTo-Json -Depth 10
    }

    return Invoke-RestMethod @arguments
}

function Wait-ForApi {
    param([string]$BaseUrl, [int]$Attempts = 120)

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

function Assert-True {
    param([bool]$Condition, [string]$Message)

    if (-not $Condition) {
        throw $Message
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

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$SmokeCompanyRuntimeScript = Join-Path $PSScriptRoot "smoke-company-runtime.ps1"
. $SmokeCompanyRuntimeScript

$BaseUrl = "http://127.0.0.1:$Port"
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\time-tracking"
$DatabasePath = Join-Path $SmokeRoot "time-tracking-smoke.db"

New-Item -ItemType Directory -Force -Path $SmokeRoot | Out-Null
Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue

Write-Step "Building API."
dotnet build "$RepositoryRoot\Zayed.Api\Zayed.Api.csproj" --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q
if ($LASTEXITCODE -ne 0) {
    throw "Build failed."
}

$api = $null
try {
    Write-Step "Starting API on $BaseUrl with temporary SQLite database."
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

    $api = [System.Diagnostics.Process]::Start($startInfo)
    Wait-ForApi -BaseUrl $BaseUrl
    Initialize-SmokeCompanyRuntime -BaseUrl $BaseUrl -DatabasePath $DatabasePath

    $login = $null
    foreach ($password in @("SmokeAdmin123!", "admin")) {
        try {
            $login = Invoke-Json -Method Post -Uri "$BaseUrl/api/auth/login" -Body @{
                userName = "admin"
                password = $password
            }
            break
        }
        catch {
            if ($_.Exception.Response.StatusCode.value__ -ne 401) {
                throw
            }
        }
    }

    if ($null -eq $login) {
        throw "Smoke admin login failed."
    }
    $headers = @{ Authorization = "Bearer $($login.token)" }

    Write-Step "Checking empty list and summary."
    $empty = Invoke-Json -Method Get -Uri "$BaseUrl/api/time-entries?pageSize=10" -Headers $headers
    Assert-True ($empty.totalCount -eq 0) "Expected an empty time entry list."

    $customers = Invoke-Json -Method Get -Uri "$BaseUrl/api/customers?pageSize=1" -Headers $headers
    $items = Invoke-Json -Method Get -Uri "$BaseUrl/api/items?pageSize=20" -Headers $headers
    $customer = $customers.items[0]
    $serviceItem = $items.items | Where-Object { $_.itemType -eq 2 } | Select-Object -First 1
    if ($null -eq $serviceItem) {
        $serviceItem = $items.items[0]
    }

    Write-Step "Creating, approving, and marking a billable time entry."
    $entry = Invoke-Json -Method Post -Uri "$BaseUrl/api/time-entries" -Headers $headers -Body @{
        workDate = "2026-05-30"
        personName = "QA Time User"
        hours = 2.5
        activity = "Implementation"
        notes = "SQLite smoke"
        customerId = $customer.id
        serviceItemId = $serviceItem.id
        isBillable = $true
    }

    Assert-True ($entry.personName -eq "QA Time User") "Created time entry was not returned."

    $list = Invoke-Json -Method Get -Uri "$BaseUrl/api/time-entries?pageSize=10" -Headers $headers
    Assert-True ($list.totalCount -eq 1) "Time entry list did not return the created entry."
    Assert-True ([decimal]$list.totalHours -eq 2.5) "Time entry list total hours is wrong."

    $approved = Invoke-Json -Method Post -Uri "$BaseUrl/api/time-entries/$($entry.id)/approve" -Headers $headers
    Assert-True ($approved.status -eq 2 -or $approved.status -eq "Approved") "Approve failed."

    $billable = Invoke-Json -Method Post -Uri "$BaseUrl/api/time-entries/$($entry.id)/mark-billable" -Headers $headers
    Assert-True ($billable.status -eq 5 -or $billable.status -eq "Billable") "Mark billable failed."

    $summary = Invoke-Json -Method Get -Uri "$BaseUrl/api/time-entries/reports/summary" -Headers $headers
    Assert-True ($summary.entryCount -eq 1) "Time entry summary did not include the created entry."

    [pscustomobject]@{
        timeEntryId = $entry.id
        listCount = $list.totalCount
        totalHours = $list.totalHours
        billableHours = $list.billableHours
        summaryEntries = $summary.entryCount
        finalStatus = $billable.status
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
