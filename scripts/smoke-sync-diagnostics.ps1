param(
    [string]$BaseUrl = "http://localhost:5014"
)

$ErrorActionPreference = "Stop"

Write-Host "Checking sync overview..." -ForegroundColor Cyan
$overview = Invoke-RestMethod "$BaseUrl/api/sync/overview"

Write-Host "Checking sync documents..." -ForegroundColor Cyan
$documents = Invoke-RestMethod "$BaseUrl/api/sync/documents?take=5"

[pscustomobject]@{
    TotalDocuments   = $overview.totalDocuments
    LocalOnlyCount   = $overview.localOnlyCount
    PendingSyncCount = $overview.pendingSyncCount
    SyncFailedCount  = $overview.syncFailedCount
    SampleCount      = @($documents).Count
} | Format-List
