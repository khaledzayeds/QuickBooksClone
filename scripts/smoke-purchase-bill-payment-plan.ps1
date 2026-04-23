param(
    [int]$Port = 5092,
    [switch]$KeepDatabase
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[purchase-bill-payment-plan-smoke] $Message"
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
        [string]$DatabasePath
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
$SmokeRoot = Join-Path $RepositoryRoot "artifacts\smoke\purchase-bill-payment-plan"
$DatabasePath = Join-Path $SmokeRoot "quickbooksclone-purchase-bill-payment-plan.db"

New-Item -ItemType Directory -Force -Path $SmokeRoot | Out-Null
Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue

Write-Step "Building API."
dotnet build "$RepositoryRoot\QuickBooksClone.Api\QuickBooksClone.Api.csproj" --no-restore /nr:false /m:1 /p:UseSharedCompilation=false -v:q

$api = $null
try {
    Write-Step "Starting API on $BaseUrl with temporary SQLite database."
    $api = Start-SmokeApi -BaseUrl $BaseUrl -DatabasePath $DatabasePath

    $vendors = Invoke-Json -Method Get -Uri "$BaseUrl/api/vendors?page=1&pageSize=10"
    $items = Invoke-Json -Method Get -Uri "$BaseUrl/api/items?page=1&pageSize=20"
    $accounts = Invoke-Json -Method Get -Uri "$BaseUrl/api/accounts?page=1&pageSize=50&includeInactive=true"

    $vendor = $vendors.items[0]
    $item = ($items.items | Where-Object { $_.itemType -eq 2 -or $_.itemType -eq 3 })[0]
    $cashAccount = ($accounts.items | Where-Object { $_.code -eq '1000' })[0]

    Write-Step "Creating posted purchase bill."
    $bill = Invoke-Json -Method Post -Uri "$BaseUrl/api/purchase-bills" -Body @{
        vendorId = $vendor.id
        billDate = "2026-04-23"
        dueDate = "2026-05-23"
        saveMode = 2
        lines = @(
            @{
                itemId = $item.id
                description = $item.name
                quantity = 2
                unitCost = 150
            }
        )
    }

    Write-Step "Validating initial payment plan."
    $planBefore = Invoke-Json -Method Get -Uri "$BaseUrl/api/purchase-bills/$($bill.id)/payment-plan"
    Assert-True ($planBefore.canPay -eq $true) "Posted purchase bill should allow payment."
    Assert-True ($planBefore.balanceDue -eq $bill.balanceDue) "Payment plan should expose the live purchase-bill balance."
    Assert-True ($planBefore.linkedPayments.Count -eq 0) "No linked vendor payments should exist before payment."

    Write-Step "Paying purchase bill."
    $payment = Invoke-Json -Method Post -Uri "$BaseUrl/api/vendor-payments" -Body @{
        purchaseBillId = $bill.id
        paymentAccountId = $cashAccount.id
        paymentDate = "2026-04-23"
        amount = $bill.balanceDue
        paymentMethod = "Cash"
    }

    Write-Step "Validating payment plan after vendor payment."
    $planAfter = Invoke-Json -Method Get -Uri "$BaseUrl/api/purchase-bills/$($bill.id)/payment-plan"
    Assert-True ($planAfter.isFullyPaid -eq $true) "Payment plan should report the purchase bill as fully paid."
    Assert-True ($planAfter.balanceDue -eq 0) "Purchase-bill balance should be zero after full payment."
    Assert-True ($planAfter.linkedPayments.Count -eq 1) "Payment plan should include the linked vendor payment."
    Assert-True ($planAfter.linkedPayments[0].id -eq $payment.id) "Payment plan linked vendor payment id mismatch."

    [pscustomobject]@{
        billNumber = $bill.billNumber
        paymentNumber = $payment.paymentNumber
        canPayBefore = $planBefore.canPay
        isFullyPaidAfter = $planAfter.isFullyPaid
        linkedPaymentCount = $planAfter.linkedPayments.Count
    } | ConvertTo-Json
}
finally {
    Stop-SmokeApi -Process $api

    if (-not $KeepDatabase) {
        Remove-Item -LiteralPath $DatabasePath, "$DatabasePath-shm", "$DatabasePath-wal" -Force -ErrorAction SilentlyContinue
    }
}
