param(
    [string]$BaseUrl = "http://127.0.0.1:5073"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$apiProject = Join-Path $root "QuickBooksClone.Api\\QuickBooksClone.Api.csproj"
$runId = [DateTimeOffset]::UtcNow.ToString("yyyyMMddHHmmss")
$logsPath = Join-Path $root "artifacts\\smoke\\backup-policy\\$runId"
$databasePath = Join-Path $logsPath "backup-policy.db"
$backupPath = Join-Path $logsPath "backups"

New-Item -ItemType Directory -Force -Path $logsPath | Out-Null

Write-Host "Building API..."
dotnet build $apiProject --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q
if ($LASTEXITCODE -ne 0) { throw "Build failed." }

$process = $null
try {
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "dotnet"
    $startInfo.Arguments = "run --no-build --project `"$apiProject`" --urls `"$BaseUrl`""
    $startInfo.WorkingDirectory = Split-Path $apiProject
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.Environment["ASPNETCORE_ENVIRONMENT"] = "Development"
    $startInfo.Environment["ASPNETCORE_DETAILEDERRORS"] = "true"
    $startInfo.Environment["ConnectionStrings__QuickBooksClone"] = "Data Source=$databasePath"
    $startInfo.Environment["Database__BackupDirectory"] = $backupPath

    $process = [System.Diagnostics.Process]::Start($startInfo)
    $null = $process
    $ready = $false
    1..30 | ForEach-Object {
        Start-Sleep -Seconds 1

        try {
            Invoke-RestMethod "$BaseUrl/api/database/settings" | Out-Null
            $ready = $true
            return
        }
        catch {
            if ($process.HasExited) {
                $stdOut = $process.StandardOutput.ReadToEnd()
                $stdErr = $process.StandardError.ReadToEnd()
                throw "API process exited before becoming ready.`nSTDOUT:`n$stdOut`nSTDERR:`n$stdErr"
            }
        }
    }

    if (-not $ready) {
        $stdOut = $process.StandardOutput.ReadToEnd()
        $stdErr = $process.StandardError.ReadToEnd()
        throw "API did not become ready in time.`nSTDOUT:`n$stdOut`nSTDERR:`n$stdErr"
    }

    $settings = Invoke-RestMethod "$BaseUrl/api/database/settings"
    if ($settings.retentionCount -lt 1) {
        throw "Expected positive default retention count."
    }

    $updatedSettings = Invoke-RestMethod `
        -Method Put `
        -Uri "$BaseUrl/api/database/settings" `
        -ContentType "application/json" `
        -Body (@{
            autoBackupEnabled = $true
            scheduleMode = "Daily"
            runAtHourLocal = 2
            retentionCount = 2
            createSafetyBackupBeforeRestore = $true
            preferredLabelPrefix = "daily"
            updatedBy = "smoke"
        } | ConvertTo-Json)

    if (-not $updatedSettings.autoBackupEnabled) {
        throw "Expected auto backup to be enabled."
    }

    1..3 | ForEach-Object {
        try {
            $backup = Invoke-RestMethod `
                -Method Post `
                -Uri "$BaseUrl/api/database/backups" `
                -ContentType "application/json" `
                -Body (@{
                    label = "smoke-$_"
                    requestedBy = "smoke"
                    reason = "Retention validation $_"
                } | ConvertTo-Json)
        }
        catch {
            $responseBody = $null
            if ($_.Exception.Response) {
                $stream = $_.Exception.Response.GetResponseStream()
                if ($stream) {
                    $reader = New-Object System.IO.StreamReader($stream)
                    $responseBody = $reader.ReadToEnd()
                    $reader.Dispose()
                    $stream.Dispose()
                }
            }

            if ($process -and -not $process.HasExited) {
                $process.Kill()
                $process.WaitForExit(3000)
            }

            $stdOut = $process.StandardOutput.ReadToEnd()
            $stdErr = $process.StandardError.ReadToEnd()
            throw "Create backup failed. Response: $($_.ErrorDetails.Message)`nBODY:`n$responseBody`nSTDOUT:`n$stdOut`nSTDERR:`n$stdErr"
        }

        if ($backup.backupKind -ne "Manual") {
            throw "Expected manual backup kind."
        }

        Start-Sleep -Seconds 1
    }

    $backups = Invoke-RestMethod "$BaseUrl/api/database/backups"
    if ($backups.totalCount -ne 2) {
        throw "Expected retention policy to keep 2 manual backups, found $($backups.totalCount)."
    }

    $restoreAttempt = $null
    try {
        Invoke-RestMethod `
            -Method Post `
            -Uri "$BaseUrl/api/database/backups/restore" `
            -ContentType "application/json" `
            -Body (@{
                fileName = $backups.items[0].fileName
                createSafetyBackup = $true
                confirmRestore = $false
                requestedBy = "smoke"
                reason = "Should fail"
            } | ConvertTo-Json) | Out-Null

        throw "Restore without confirmation should have failed."
    }
    catch {
        $restoreAttempt = $_
    }

    if (-not $restoreAttempt) {
        throw "Expected restore without confirmation to fail."
    }

    $restore = Invoke-RestMethod `
        -Method Post `
        -Uri "$BaseUrl/api/database/backups/restore" `
        -ContentType "application/json" `
        -Body (@{
            fileName = $backups.items[0].fileName
            createSafetyBackup = $true
            confirmRestore = $true
            requestedBy = "smoke"
            reason = "Audit validation"
        } | ConvertTo-Json)

    if (-not $restore.createdSafetyBackup) {
        throw "Expected restore to create a safety backup."
    }

    $audits = Invoke-RestMethod "$BaseUrl/api/database/restore-audits"
    if ($audits.totalCount -lt 1) {
        throw "Expected at least one restore audit entry."
    }

    if ($audits.items[0].requestedBy -ne "smoke") {
        throw "Expected restore audit to keep requestedBy."
    }

    if ($audits.items[0].reason -ne "Audit validation") {
        throw "Expected restore audit to keep reason."
    }

    Write-Host "Backup policy smoke succeeded."
}
finally {
    if ($process -and -not $process.HasExited) {
        $process.Kill()
        $null = $process.WaitForExit(3000)
    }
}
