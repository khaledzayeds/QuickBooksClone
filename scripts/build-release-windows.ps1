param(
    [string]$Configuration = "Release",
    [string]$Runtime = "win-x64",
    [string]$ArtifactName = "ZayedOfflineERP-v1-win-x64"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$flutterProject = Join-Path $repoRoot "QuickBooksFlutter\zayed"
$apiProject = Join-Path $repoRoot "Zayed.Api\Zayed.Api.csproj"
$artifactsRoot = Join-Path $repoRoot "artifacts"
$releaseRoot = Join-Path $artifactsRoot $ArtifactName
$apiPublish = Join-Path $repoRoot "artifacts\api-publish-$Runtime"
$flutterRelease = Join-Path $flutterProject "build\windows\x64\runner\Release"

Write-Host "Building Zayed Offline ERP v1 release..." -ForegroundColor Cyan

if (Test-Path $releaseRoot) {
    Remove-Item -LiteralPath $releaseRoot -Recurse -Force
}

if (Test-Path $apiPublish) {
    Remove-Item -LiteralPath $apiPublish -Recurse -Force
}

New-Item -ItemType Directory -Path $releaseRoot | Out-Null
New-Item -ItemType Directory -Path $apiPublish | Out-Null

Write-Host "Publishing local API..." -ForegroundColor Cyan
dotnet publish $apiProject `
    -c $Configuration `
    -r $Runtime `
    --self-contained true `
    -o $apiPublish `
    /p:PublishSingleFile=false `
    /p:IncludeNativeLibrariesForSelfExtract=true

$apiExe = Join-Path $apiPublish "Zayed.Api.exe"
if (-not (Test-Path $apiExe)) {
    throw "API publish did not produce Zayed.Api.exe. Check .NET SDK/runtime support for $Runtime."
}

Write-Host "Building Flutter Windows app..." -ForegroundColor Cyan
Push-Location $flutterProject
try {
    flutter pub get
    flutter build windows --release
}
finally {
    Pop-Location
}

$appExe = Join-Path $flutterRelease "Zayed.exe"
if (-not (Test-Path $appExe)) {
    throw "Flutter build did not produce Zayed.exe at $flutterRelease."
}

Write-Host "Copying release files..." -ForegroundColor Cyan
Copy-Item -Path (Join-Path $flutterRelease "*") -Destination $releaseRoot -Recurse -Force

$releaseApiDir = Join-Path $releaseRoot "api"
New-Item -ItemType Directory -Path $releaseApiDir | Out-Null
Copy-Item -Path (Join-Path $apiPublish "*") -Destination $releaseApiDir -Recurse -Force

$releaseReadme = @"
# Zayed Offline ERP v1

## Run

Open `Zayed.exe` from this folder. The desktop app starts the local Zayed service from `api/Zayed.Api.exe` automatically.

## Data

Zayed Offline ERP v1 uses a local SQLite database. Company database files are created and opened through the company launcher inside the app. Keep company database files and backup files in a safe folder.

## Backups

Create a backup before importing, restoring, or moving company database files. Restore operations should only be done from trusted backup files.

## Support

If the app shows "Zayed service files are missing", reinstall Zayed from a clean release folder. If the service cannot start, restart Windows and contact support with the release folder name and Windows version.
"@

Set-Content -LiteralPath (Join-Path $releaseRoot "README.txt") -Value $releaseReadme -Encoding UTF8

Write-Host "Release created:" -ForegroundColor Green
Write-Host $releaseRoot
