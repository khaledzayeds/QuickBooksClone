param(
    [string]$OutputPath = ".\\artifacts\\smoke\\sqlserver\\quickbooksclone-sqlserver.sql"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$apiProject = Join-Path $root "QuickBooksClone.Api\\QuickBooksClone.Api.csproj"
$migrationsProject = Join-Path $root "QuickBooksClone.SqlServerMigrations\\QuickBooksClone.SqlServerMigrations.csproj"
$resolvedOutputPath = [System.IO.Path]::GetFullPath((Join-Path $root $OutputPath))
$outputDirectory = Split-Path -Parent $resolvedOutputPath

if (-not (Test-Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

Write-Host "Building API startup project..."
dotnet build $apiProject --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q
if ($LASTEXITCODE -ne 0) {
    throw "Build failed."
}

Write-Host "Generating idempotent SQL Server migration script..."
dotnet ef migrations script `
    --project $migrationsProject `
    --startup-project $apiProject `
    --context QuickBooksCloneDbContext `
    --output $resolvedOutputPath `
    --idempotent

if ($LASTEXITCODE -ne 0) {
    throw "Failed to generate SQL Server migration script."
}

if (-not (Test-Path $resolvedOutputPath)) {
    throw "Expected migration script was not created: $resolvedOutputPath"
}

$scriptContent = Get-Content $resolvedOutputPath -Raw
$expectedTokens = @(
    "__EFMigrationsHistory",
    "[accounts]",
    "[company_settings]"
)

foreach ($token in $expectedTokens) {
    if ($scriptContent -notmatch [Regex]::Escape($token)) {
        throw "Generated script is missing expected token: $token"
    }
}

Write-Host "SQL Server migration smoke succeeded: $resolvedOutputPath"
