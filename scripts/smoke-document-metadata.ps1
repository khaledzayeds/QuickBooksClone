param(
    [int]$Port = 5084,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[document-metadata-smoke] $Message"
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
    param(
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [int]$Attempts = 90
    )

    for ($i = 0; $i -lt $Attempts; $i++) {
        try {
            Invoke-Json -Method Get -Uri "$BaseUrl/api/vendors?pageSize=1" | Out-Null
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
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$BaseUrl = "http://localhost:$Port"
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\document-metadata"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-document-metadata.db"

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

    $vendors = Invoke-Json -Method Get -Uri "$BaseUrl/api/vendors?pageSize=10"
    $items = Invoke-Json -Method Get -Uri "$BaseUrl/api/items?pageSize=10"
    $vendor = $vendors.items | Select-Object -First 1
    $item = $items.items | Select-Object -First 1

    Assert-True ($null -ne $vendor) "Expected at least one seeded vendor."
    Assert-True ($null -ne $item) "Expected at least one seeded item."

    Write-Step "Creating purchase order used as metadata owner."
    $order = Invoke-Json -Method Post -Uri "$BaseUrl/api/purchase-orders" -Body @{
        vendorId = $vendor.id
        orderDate = "2026-04-28"
        expectedDate = "2026-05-05"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                description = "Metadata smoke line"
                quantity = 2
                unitCost = 40
            }
        )
    }

    Write-Step "Updating document memo, template, ship-to, and reference metadata."
    $updated = Invoke-Json -Method Put -Uri "$BaseUrl/api/documents/purchase-order/$($order.id)/metadata" -Body @{
        publicMemo = "Visible purchase memo"
        internalNote = "Internal receiving note"
        externalReference = "EXT-PO-001"
        templateName = "Default Purchase Order"
        shipToName = "Main Warehouse"
        shipToAddressLine1 = "Warehouse Street 1"
        shipToAddressLine2 = "Dock 2"
        shipToCity = "Cairo"
        shipToRegion = "Cairo"
        shipToPostalCode = "11511"
        shipToCountry = "Egypt"
    }

    Assert-True ($updated.documentType -eq "purchase-order") "Document type was not normalized."
    Assert-True ($updated.publicMemo -eq "Visible purchase memo") "Public memo was not saved."
    Assert-True ($updated.shipToName -eq "Main Warehouse") "Ship-to name was not saved."
    Assert-True ($updated.syncStatus -eq 1) "Metadata should be pending sync after local update."
    Assert-True ($updated.deviceId.Length -gt 0) "Metadata should carry device identity."
    Assert-True ($updated.documentNo.StartsWith("META-PURCHASE-ORDER-")) "Metadata document number was not generated."

    Write-Step "Adding attachment metadata without storing file bytes."
    $attachment = Invoke-Json -Method Post -Uri "$BaseUrl/api/documents/purchase-order/$($order.id)/metadata/attachments" -Body @{
        fileName = "po-attachment.pdf"
        contentType = "application/pdf"
        fileSizeBytes = 2048
        storageKey = "local/purchase-orders/$($order.id)/po-attachment.pdf"
    }

    Assert-True ($attachment.fileName -eq "po-attachment.pdf") "Attachment metadata was not returned."

    $loaded = Invoke-Json -Method Get -Uri "$BaseUrl/api/documents/purchase-order/$($order.id)/metadata"
    Assert-True ($loaded.attachments.Count -eq 1) "Attachment metadata was not persisted."
    Assert-True ($loaded.attachments[0].storageKey -like "local/purchase-orders/*") "Attachment storage key was not saved."

    Write-Step "Removing attachment metadata."
    Invoke-RestMethod -Method Delete -Uri "$BaseUrl/api/documents/purchase-order/$($order.id)/metadata/attachments/$($attachment.id)" -TimeoutSec 30 | Out-Null

    $afterRemove = Invoke-Json -Method Get -Uri "$BaseUrl/api/documents/purchase-order/$($order.id)/metadata"
    Assert-True ($afterRemove.attachments.Count -eq 0) "Attachment metadata was not removed."

    [pscustomobject]@{
        purchaseOrderId = $order.id
        metadataDocumentNo = $afterRemove.documentNo
        syncStatus = $afterRemove.syncStatus
        templateName = $afterRemove.templateName
        attachmentsAfterRemove = $afterRemove.attachments.Count
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
