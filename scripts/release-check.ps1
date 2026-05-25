param(
    [switch]$SkipFlutterBuild,
    [switch]$SkipReleasePackage
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$flutterProject = Join-Path $repoRoot "QuickBooksFlutter\zayed"

function Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "== $Message ==" -ForegroundColor Cyan
}

Step "Shut down stale build servers"
dotnet build-server shutdown

Step "Build backend solution"
dotnet build (Join-Path $repoRoot "Zayed.slnx") --no-restore --disable-build-servers /m:1 /p:UseSharedCompilation=false /p:RunAnalyzers=false -v:minimal

Step "Run core backend smoke tests"
& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "smoke-core-backend.ps1")

Step "Flutter pub get"
Push-Location $flutterProject
try {
    flutter pub get

    Step "Flutter analyze"
    flutter analyze

    if (-not $SkipFlutterBuild) {
        Step "Flutter Windows release build"
        flutter build windows --release
    }
}
finally {
    Pop-Location
}

if (-not $SkipReleasePackage) {
    Step "Build Windows release folder"
    & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "build-release-windows.ps1")
}

Write-Host ""
Write-Host "Release check completed." -ForegroundColor Green
