param(
    [switch]$KeepDatabases
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[core-backend-smoke] $Message"
}

$RepositoryRoot = Split-Path -Parent $PSScriptRoot

$tests = @(
    @{ Name = "Persistence"; Script = "smoke-persistence.ps1" },
    @{ Name = "Purchase Orders"; Script = "smoke-purchase-orders.ps1" },
    @{ Name = "Receive Inventory"; Script = "smoke-receive-inventory.ps1" },
    @{ Name = "Bills Against Receipts"; Script = "smoke-bills-against-receipts.ps1" },
    @{ Name = "Purchase Workflow Plans"; Script = "smoke-purchase-workflow-plans.ps1" },
    @{ Name = "Purchase Bill Payment Plan"; Script = "smoke-purchase-bill-payment-plan.ps1" },
    @{ Name = "Estimates and Sales Orders"; Script = "smoke-estimates-sales-orders.ps1" },
    @{ Name = "Sales Workflow Plans"; Script = "smoke-sales-workflow-plans.ps1" },
    @{ Name = "Sales Receipts"; Script = "smoke-sales-receipts.ps1" },
    @{ Name = "Document Metadata"; Script = "smoke-document-metadata.ps1" },
    @{ Name = "Security Foundation"; Script = "smoke-security-foundation.ps1" },
    @{ Name = "Auth Sessions"; Script = "smoke-auth-sessions.ps1" },
    @{ Name = "Business Authorization"; Script = "smoke-business-authorization.ps1" },
    @{ Name = "Audit Trail"; Script = "smoke-audit-trail.ps1" },
    @{ Name = "Tax Foundation"; Script = "smoke-tax-foundation.ps1" },
    @{ Name = "Non-posting Tax Preview"; Script = "smoke-nonposting-tax-preview.ps1" },
    @{ Name = "API Contract"; Script = "smoke-api-contract.ps1" },
    @{ Name = "Settings"; Script = "smoke-settings.ps1" },
    @{ Name = "Backup Policy"; Script = "smoke-backup-policy.ps1" }
)

$results = New-Object System.Collections.Generic.List[object]

foreach ($test in $tests) {
    $scriptPath = Join-Path $PSScriptRoot $test.Script
    Write-Step "Running $($test.Name) via $($test.Script)."

    $start = Get-Date
    $arguments = @(
        "-ExecutionPolicy", "Bypass",
        "-File", $scriptPath
    )

    if ($KeepDatabases) {
        $arguments += "-KeepDatabase"
    }

    & powershell @arguments

    $results.Add([pscustomobject]@{
        name = $test.Name
        script = $test.Script
        durationSeconds = [math]::Round(((Get-Date) - $start).TotalSeconds, 2)
        status = "Passed"
    }) | Out-Null
}

Write-Step "All core backend smoke tests passed."
$results | ConvertTo-Json -Depth 5
