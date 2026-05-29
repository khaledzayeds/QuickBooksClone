function Initialize-SmokeCompanyRuntime {
    param(
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [Parameter(Mandatory = $true)][string]$DatabasePath
    )

    $companyId = [guid]::NewGuid().ToString()
    $companyName = "Smoke Company"

    $openBody = @{
        companyId = $companyId
        companyName = $companyName
        databasePath = $DatabasePath
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod `
        -Method Post `
        -Uri "$BaseUrl/api/companies/open" `
        -ContentType "application/json" `
        -Body $openBody `
        -TimeoutSec 120 | Out-Null

    $status = Invoke-RestMethod -Method Get -Uri "$BaseUrl/api/setup/status" -TimeoutSec 120
    if (-not $status.isInitialized) {
        $setupBody = @{
            companyName = $companyName
            currency = "EGP"
            country = "Egypt"
            timeZoneId = "Africa/Cairo"
            defaultLanguage = "en"
            legalName = $companyName
            email = "smoke@example.com"
            phone = "+2000000000"
            adminUserName = "admin"
            adminDisplayName = "Smoke Admin"
            adminEmail = "admin@example.com"
            initialAdminSecret = "SmokeAdmin123!"
            fiscalYearStartMonth = 1
            fiscalYearStartDay = 1
            taxesEnabled = $true
            pricesIncludeTax = $false
            defaultSalesTaxRate = 14
            defaultPurchaseTaxRate = 14
            inventoryEnabled = $true
            defaultWarehouseName = "Main"
            servicesEnabled = $true
        } | ConvertTo-Json -Depth 5

        try {
            Invoke-RestMethod `
                -Method Post `
                -Uri "$BaseUrl/api/setup/initialize-company" `
                -ContentType "application/json" `
                -Body $setupBody `
                -TimeoutSec 120 | Out-Null
        }
        catch {
            if ($_.Exception.Response.StatusCode.value__ -ne 409) {
                throw
            }
        }
    }

    $login = $null
    foreach ($password in @("SmokeAdmin123!", "admin")) {
        $loginBody = @{
            userName = "admin"
            password = $password
        } | ConvertTo-Json -Depth 5

        try {
            $login = Invoke-RestMethod `
                -Method Post `
                -Uri "$BaseUrl/api/auth/login" `
                -ContentType "application/json" `
                -Body $loginBody `
                -TimeoutSec 120
            break
        }
        catch {
            if ($_.Exception.Response.StatusCode.value__ -ne 401) {
                throw
            }
        }
    }

    if ($null -eq $login) {
        throw "Smoke admin login failed."
    }

    $script:SmokeAuthToken = $login.token
    $Global:PSDefaultParameterValues["Invoke-RestMethod:Headers"] = @{
        Authorization = "Bearer $($login.token)"
    }
}
