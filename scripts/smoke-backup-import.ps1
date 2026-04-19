param(
    [string]$BaseUrl = "http://127.0.0.1:5075"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$runId = [DateTimeOffset]::UtcNow.ToString("yyyyMMddHHmmss")
$logsPath = Join-Path $root "artifacts\\smoke\\backup-import\\$runId"
$databasePath = Join-Path $logsPath "backup-import.db"
$backupPath = Join-Path $logsPath "backups"
$apiProject = Join-Path $root "QuickBooksClone.Api\\QuickBooksClone.Api.csproj"

New-Item -ItemType Directory -Force -Path $logsPath | Out-Null

Write-Host "Building API..."
dotnet build $apiProject --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q
if ($LASTEXITCODE -ne 0) { throw "Build failed." }

$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = "dotnet"
$startInfo.Arguments = "run --no-build --project `"$apiProject`" --urls `"$BaseUrl`""
$startInfo.WorkingDirectory = Split-Path $apiProject
$startInfo.UseShellExecute = $false
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.Environment["ASPNETCORE_ENVIRONMENT"] = "Development"
$startInfo.Environment["ConnectionStrings__QuickBooksClone"] = "Data Source=$databasePath"
$startInfo.Environment["Database__BackupDirectory"] = $backupPath

$process = [System.Diagnostics.Process]::Start($startInfo)
$null = $process

try {
    $ready = $false
    1..60 | ForEach-Object {
        Start-Sleep -Seconds 1
        try {
            Invoke-RestMethod "$BaseUrl/api/database/status" | Out-Null
            $ready = $true
            return
        }
        catch {
            if ($process.HasExited) {
                throw "API process exited before becoming ready."
            }
        }
    }

    if (-not $ready) {
        $stdOut = $process.StandardOutput.ReadToEnd()
        $stdErr = $process.StandardError.ReadToEnd()
        throw "API did not become ready in time.`nSTDOUT:`n$stdOut`nSTDERR:`n$stdErr"
    }

    $createdBackup = Invoke-RestMethod `
        -Method Post `
        -Uri "$BaseUrl/api/database/backups" `
        -ContentType "application/json" `
        -Body (@{
            label = "seed"
            requestedBy = "smoke"
            reason = "Create import source"
        } | ConvertTo-Json)

    $sourceBackup = Join-Path $backupPath $createdBackup.fileName
    if (-not (Test-Path $sourceBackup)) {
        throw "Source backup file was not created."
    }

    $boundary = "---------------------------$([Guid]::NewGuid().ToString('N'))"
    $lineBreak = "`r`n"
    $fileBytes = [System.IO.File]::ReadAllBytes($sourceBackup)
    $header = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"label`"",
        "",
        "client-copy",
        "--$boundary",
        "Content-Disposition: form-data; name=`"requestedBy`"",
        "",
        "smoke",
        "--$boundary",
        "Content-Disposition: form-data; name=`"reason`"",
        "",
        "Import validation",
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"external.db`"",
        "Content-Type: application/octet-stream",
        "",
        ""
    ) -join $lineBreak

    $footer = "$lineBreak--$boundary--$lineBreak"
    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
    $footerBytes = [System.Text.Encoding]::UTF8.GetBytes($footer)
    $bodyBytes = New-Object byte[] ($headerBytes.Length + $fileBytes.Length + $footerBytes.Length)
    [Array]::Copy($headerBytes, 0, $bodyBytes, 0, $headerBytes.Length)
    [Array]::Copy($fileBytes, 0, $bodyBytes, $headerBytes.Length, $fileBytes.Length)
    [Array]::Copy($footerBytes, 0, $bodyBytes, $headerBytes.Length + $fileBytes.Length, $footerBytes.Length)

    $imported = Invoke-RestMethod `
        -Method Post `
        -Uri "$BaseUrl/api/database/backups/import" `
        -ContentType "multipart/form-data; boundary=$boundary" `
        -Body $bodyBytes

    if ($imported.backupKind -ne "Imported") {
        throw "Expected imported backup kind."
    }

    $backups = Invoke-RestMethod "$BaseUrl/api/database/backups"
    $importedItems = @($backups.items | Where-Object { $_.backupKind -eq "Imported" })
    if ($importedItems.Count -lt 1) {
        throw "Expected imported backup to appear in backup list. Imported response: $($imported | ConvertTo-Json -Depth 10) Backup list: $($backups | ConvertTo-Json -Depth 10)"
    }

    Write-Host "Backup import smoke succeeded."
}
finally {
    if ($process -and -not $process.HasExited) {
        $process.Kill()
        $null = $process.WaitForExit(3000)
    }
}
