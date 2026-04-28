param(
    [int]$Port = 5086,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[auth-smoke] $Message"
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
            Invoke-Json -Method Get -Uri "$BaseUrl/api/security/permissions" | Out-Null
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
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\auth"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-auth.db"

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

    Write-Step "Logging in with seeded admin account."
    $login = Invoke-Json -Method Post -Uri "$BaseUrl/api/auth/login" -Body @{
        userName = "admin"
        password = "admin"
    }

    Assert-True (-not [string]::IsNullOrWhiteSpace($login.token)) "Login did not return a token."
    Assert-True ($login.user.userName -eq "admin") "Login did not return admin user."
    Assert-True (@($login.user.roles | Where-Object { $_.roleKey -eq "ADMIN" }).Count -eq 1) "Admin role was not returned."
    Assert-True ($login.user.effectivePermissions.Count -ge 10) "Admin permissions were not returned."

    Write-Step "Reading current session using bearer token."
    $me = Invoke-Json -Method Get -Uri "$BaseUrl/api/auth/me" -Token $login.token
    Assert-True ($me.user.id -eq $login.user.id) "Current session did not return the logged-in user."

    Write-Step "Changing password invalidates current sessions."
    Invoke-RestMethod -Method Put -Uri "$BaseUrl/api/auth/users/$($login.user.id)/password" -ContentType "application/json" -Body (@{ newPassword = "new-admin-pass" } | ConvertTo-Json) -TimeoutSec 30 | Out-Null

    try {
        Invoke-Json -Method Get -Uri "$BaseUrl/api/auth/me" -Token $login.token | Out-Null
        throw "Old token should have been invalidated after password change."
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -ne 401) {
            throw
        }
    }

    $secondLogin = Invoke-Json -Method Post -Uri "$BaseUrl/api/auth/login" -Body @{
        userName = "admin"
        password = "new-admin-pass"
    }
    Assert-True (-not [string]::IsNullOrWhiteSpace($secondLogin.token)) "Login with new password failed."

    Write-Step "Logging out revokes the session."
    Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/auth/logout" -Headers @{ Authorization = "Bearer $($secondLogin.token)" } -TimeoutSec 30 | Out-Null

    try {
        Invoke-Json -Method Get -Uri "$BaseUrl/api/auth/me" -Token $secondLogin.token | Out-Null
        throw "Token should have been invalidated after logout."
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -ne 401) {
            throw
        }
    }

    [pscustomobject]@{
        userName = $login.user.userName
        permissionCount = $login.user.effectivePermissions.Count
        firstTokenInvalidated = $true
        logoutInvalidatedSecondToken = $true
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
