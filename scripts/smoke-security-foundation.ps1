param(
    [int]$Port = 5085,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[security-smoke] $Message"
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
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\security"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-security.db"

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

    $permissions = Invoke-Json -Method Get -Uri "$BaseUrl/api/security/permissions"
    Assert-True ($permissions.Count -ge 10) "Expected seeded permission catalog."

    $roles = Invoke-Json -Method Get -Uri "$BaseUrl/api/security/roles?pageSize=50"
    Assert-True ($roles.totalCount -ge 6) "Expected seeded system roles."

    $adminRole = $roles.items | Where-Object { $_.roleKey -eq "ADMIN" } | Select-Object -First 1
    Assert-True ($null -ne $adminRole) "Expected ADMIN role."
    Assert-True ($adminRole.permissions.Count -eq $permissions.Count) "ADMIN role should have every known permission."

    $users = Invoke-Json -Method Get -Uri "$BaseUrl/api/security/users?pageSize=50"
    $adminUser = $users.items | Where-Object { $_.userName -eq "admin" } | Select-Object -First 1
    Assert-True ($null -ne $adminUser) "Expected seeded admin user."
    Assert-True (@($adminUser.roles | Where-Object { $_.roleKey -eq "ADMIN" }).Count -eq 1) "Admin user should have ADMIN role."

    Write-Step "Creating custom role and assigning it to a user."
    $customRole = Invoke-Json -Method Post -Uri "$BaseUrl/api/security/roles" -Body @{
        roleKey = "TEST-CASHIER"
        name = "Test Cashier"
        description = "Smoke test cashier role"
        permissions = @("Sales.Invoice.Manage", "Sales.Payment.Manage")
    }

    Assert-True ($customRole.roleKey -eq "TEST-CASHIER") "Custom role was not created."
    Assert-True ($customRole.permissions.Count -eq 2) "Custom role permissions were not saved."

    $user = Invoke-Json -Method Post -Uri "$BaseUrl/api/security/users" -Body @{
        userName = "smoke.cashier"
        displayName = "Smoke Cashier"
        email = $null
        roleIds = @($customRole.id)
    }

    Assert-True ($user.userName -eq "smoke.cashier") "User was not created."
    Assert-True (@($user.roles | Where-Object { $_.roleKey -eq "TEST-CASHIER" }).Count -eq 1) "User role assignment was not saved."
    Assert-True (@($user.effectivePermissions | Where-Object { $_ -eq "Sales.Payment.Manage" }).Count -eq 1) "Effective permissions were not calculated."

    Write-Step "Replacing role permissions."
    $updatedRole = Invoke-Json -Method Put -Uri "$BaseUrl/api/security/roles/$($customRole.id)/permissions" -Body @{
        permissions = @("Reports.View")
    }

    Assert-True ($updatedRole.permissions.Count -eq 1) "Role permissions were not replaced."

    $updatedUser = Invoke-Json -Method Get -Uri "$BaseUrl/api/security/users/$($user.id)"
    Assert-True (@($updatedUser.effectivePermissions | Where-Object { $_ -eq "Reports.View" }).Count -eq 1) "Updated effective permissions were not reflected."

    [pscustomobject]@{
        permissionCount = $permissions.Count
        seededRoleCount = $roles.totalCount
        customRoleId = $customRole.id
        userId = $user.id
        updatedPermission = $updatedUser.effectivePermissions[0]
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
