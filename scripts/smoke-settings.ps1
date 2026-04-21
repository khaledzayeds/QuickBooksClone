param(
    [int]$Port = 5036,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[settings-smoke] $Message"
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
        [string]$DatabasePath,
        [string]$BackupDirectory
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
    $startInfo.Environment["Database__BackupDirectory"] = $BackupDirectory
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
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\settings"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-settings-smoke.db"
$BackupDirectory = Join-Path $SmokeRoot "backups"

New-Item -ItemType Directory -Force -Path $SmokeRoot, $BackupDirectory | Out-Null
Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue

Write-Step "Building API."
dotnet build "$RepositoryRoot\QuickBooksClone.Api\QuickBooksClone.Api.csproj" --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q

$api = $null
try {
    Write-Step "Starting API with temporary settings database."
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath -BackupDirectory $BackupDirectory

    $runtime = Invoke-Json -Method Get -Uri "$BaseUrl/api/settings/runtime"
    $company = Invoke-Json -Method Get -Uri "$BaseUrl/api/settings/company"
    $device = Invoke-Json -Method Get -Uri "$BaseUrl/api/settings/device"

    Assert-True ($runtime.databaseProvider -eq "Sqlite") "Runtime settings did not report SQLite provider."
    Assert-True ($runtime.supportsBackupRestore -eq $true) "Runtime settings did not report backup support."
    Assert-True ($company.companyName -eq "QuickBooksClone Demo Company") "Default company settings were not seeded."
    Assert-True ($company.defaultLanguage -eq "ar") "Default company language was not seeded."
    Assert-True ($device.deviceId -eq "DEV01") "Default device settings were not seeded."

    Write-Step "Updating company settings."
    $updated = Invoke-Json -Method Put -Uri "$BaseUrl/api/settings/company" -Body @{
        companyName = "Zokaa Trading"
        legalName = "Zokaa Trading LLC"
        email = "finance@zokaa.example"
        phone = "+20 111 222 3333"
        currency = "SAR"
        country = "Saudi Arabia"
        timeZoneId = "Arab Standard Time"
        defaultLanguage = "en"
        taxRegistrationNumber = "300123456700003"
        addressLine1 = "King Fahd Road"
        addressLine2 = "Unit 12"
        city = "Riyadh"
        region = "Riyadh Region"
        postalCode = "12211"
        fiscalYearStartMonth = 4
        fiscalYearStartDay = 1
        defaultSalesTaxRate = 15
        defaultPurchaseTaxRate = 15
    }

    Write-Step "Updating device settings."
    $updatedDevice = Invoke-Json -Method Put -Uri "$BaseUrl/api/settings/device" -Body @{
        deviceId = "POS01"
        deviceName = "Front Counter"
    }

    Assert-True ($updated.companyName -eq "Zokaa Trading") "Company settings update did not return the new company name."
    Assert-True ($updated.currency -eq "SAR") "Company settings update did not return the new currency."
    Assert-True ($updated.defaultSalesTaxRate -eq 15) "Company settings update did not return the new sales tax rate."
    Assert-True ($updatedDevice.deviceId -eq "POS01") "Device settings update did not return the new device ID."
    Assert-True ($updatedDevice.deviceName -eq "Front Counter") "Device settings update did not return the new device name."

    Write-Step "Restarting API to verify settings persistence."
    Stop-SmokeApi -Process $api
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath -BackupDirectory $BackupDirectory

    $persistedCompany = Invoke-Json -Method Get -Uri "$BaseUrl/api/settings/company"
    $persistedRuntime = Invoke-Json -Method Get -Uri "$BaseUrl/api/settings/runtime"
    $persistedDevice = Invoke-Json -Method Get -Uri "$BaseUrl/api/settings/device"

    Assert-True ($persistedCompany.companyName -eq "Zokaa Trading") "Company settings did not persist after restart."
    Assert-True ($persistedCompany.defaultLanguage -eq "en") "Company language did not persist after restart."
    Assert-True ($persistedCompany.fiscalYearStartMonth -eq 4) "Fiscal year start month did not persist after restart."
    Assert-True ($persistedRuntime.backupDirectory -eq $BackupDirectory) "Runtime settings did not reflect configured backup directory."
    Assert-True ($persistedDevice.deviceId -eq "POS01") "Device settings did not persist after restart."

    [pscustomobject]@{
        companyName = $persistedCompany.companyName
        currency = $persistedCompany.currency
        defaultLanguage = $persistedCompany.defaultLanguage
        fiscalYearStartMonth = $persistedCompany.fiscalYearStartMonth
        salesTaxRate = $persistedCompany.defaultSalesTaxRate
        deviceId = $persistedDevice.deviceId
        deviceName = $persistedDevice.deviceName
        runtimeProvider = $persistedRuntime.databaseProvider
        runtimeBackupDirectory = $persistedRuntime.backupDirectory
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
        Get-ChildItem -LiteralPath $BackupDirectory -Filter *.db -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}
