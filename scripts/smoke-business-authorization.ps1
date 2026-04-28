param(
    [int]$Port = 5087,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[business-auth-smoke] $Message"
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

    for ($i = 0; $i -lt 90; $i++) {
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

function Assert-Status {
    param(
        [scriptblock]$Action,
        [int]$ExpectedStatus,
        [string]$Message
    )

    try {
        & $Action | Out-Null
        throw $Message
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -ne $ExpectedStatus) {
            throw
        }
    }
}

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$BaseUrl = "http://localhost:$Port"
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\business-authorization"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-business-authorization.db"

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

    Assert-Status -ExpectedStatus 401 -Message "Accounts should require authentication." -Action {
        Invoke-Json -Method Get -Uri "$BaseUrl/api/accounts?pageSize=1"
    }

    $adminLogin = Invoke-Json -Method Post -Uri "$BaseUrl/api/auth/login" -Body @{
        userName = "admin"
        password = "admin"
    }

    Assert-True (-not [string]::IsNullOrWhiteSpace($adminLogin.token)) "Expected admin token."

    $accounts = Invoke-Json -Method Get -Uri "$BaseUrl/api/accounts?pageSize=5" -Token $adminLogin.token
    Assert-True ($accounts.totalCount -gt 0) "Admin should see chart of accounts."

    $reports = Invoke-Json -Method Get -Uri "$BaseUrl/api/reports/trial-balance" -Token $adminLogin.token
    Assert-True ($null -ne $reports) "Admin should see reports."

    $roles = Invoke-Json -Method Get -Uri "$BaseUrl/api/security/roles?pageSize=50" -Token $adminLogin.token
    $readOnlyRole = $roles.items | Where-Object { $_.roleKey -eq "READONLY" } | Select-Object -First 1
    Assert-True ($null -ne $readOnlyRole) "Expected READONLY role."

    $readOnlyUser = Invoke-Json -Method Post -Uri "$BaseUrl/api/security/users" -Token $adminLogin.token -Body @{
        userName = "readonly.smoke"
        displayName = "Read Only Smoke"
        email = $null
        roleIds = @($readOnlyRole.id)
    }

    Invoke-RestMethod -Method Put -Uri "$BaseUrl/api/auth/users/$($readOnlyUser.id)/password" -Headers @{ Authorization = "Bearer $($adminLogin.token)" } -ContentType "application/json" -Body (@{ newPassword = "readonly-pass" } | ConvertTo-Json) -TimeoutSec 30 | Out-Null

    $readOnlyLogin = Invoke-Json -Method Post -Uri "$BaseUrl/api/auth/login" -Body @{
        userName = "readonly.smoke"
        password = "readonly-pass"
    }

    Invoke-Json -Method Get -Uri "$BaseUrl/api/accounts?pageSize=1" -Token $readOnlyLogin.token | Out-Null
    Invoke-Json -Method Get -Uri "$BaseUrl/api/reports/trial-balance" -Token $readOnlyLogin.token | Out-Null

    Assert-Status -ExpectedStatus 403 -Message "Read-only user should not manage accounts." -Action {
        Invoke-Json -Method Post -Uri "$BaseUrl/api/accounts" -Token $readOnlyLogin.token -Body @{
            code = "9999"
            name = "Forbidden Smoke Account"
            accountType = 1
            description = $null
            parentId = $null
        }
    }

    Assert-Status -ExpectedStatus 403 -Message "Read-only user should not access invoices." -Action {
        Invoke-Json -Method Get -Uri "$BaseUrl/api/invoices?pageSize=1" -Token $readOnlyLogin.token
    }

    [pscustomobject]@{
        adminCanViewAccounts = $true
        readOnlyCanViewAccounts = $true
        readOnlyAccountCreateForbidden = $true
        readOnlyInvoicesForbidden = $true
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
