$customer = (Invoke-RestMethod -Uri "http://localhost:5014/api/customers?includeInactive=false&page=1&pageSize=10").items[0]
$item = (Invoke-RestMethod -Uri "http://localhost:5014/api/items?includeInactive=false&page=1&pageSize=10").items[0]

$estimateBody = @{
    customerId = $customer.id
    estimateDate = "2026-04-23"
    expirationDate = "2026-05-07"
    saveMode = 2
    lines = @(
        @{
            itemId = $item.id
            description = "Verification estimate line"
            quantity = 2
            unitPrice = 750
        }
    )
} | ConvertTo-Json -Depth 5

$estimate = Invoke-RestMethod -Uri "http://localhost:5014/api/estimates" -Method Post -ContentType "application/json" -Body $estimateBody

$salesOrderBody = @{
    customerId = $customer.id
    orderDate = "2026-04-23"
    expectedDate = "2026-04-30"
    saveMode = 2
    lines = @(
        @{
            itemId = $item.id
            description = "Verification sales order line"
            quantity = 3
            unitPrice = 725
        }
    )
} | ConvertTo-Json -Depth 5

$salesOrder = Invoke-RestMethod -Uri "http://localhost:5014/api/sales-orders" -Method Post -ContentType "application/json" -Body $salesOrderBody

[pscustomobject]@{
    EstimateNo = $estimate.estimateNumber
    EstimateStatus = $estimate.status
    SalesOrderNo = $salesOrder.orderNumber
    SalesOrderStatus = $salesOrder.status
} | ConvertTo-Json -Compress
