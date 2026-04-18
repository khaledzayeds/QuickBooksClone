# QuickBooksClone API Endpoints

Current API contract for the desktop/frontend client.

Base URL:

```text
http://localhost:5014
```

Status:

```text
Iterative contract. Stable enough for current frontend work, but not final.
```

## Common Notes

- All IDs are `Guid`.
- All JSON uses camelCase.
- Current data store is in-memory, so data resets when the API restarts.
- Current authentication is not enabled yet.
- Model validation errors return `400 Bad Request`.
- Duplicate business keys return `409 Conflict` with a simple message.

Customer responses include:

- `balance`: current regular customer balance field.
- `creditBalance`: available customer credit created by paid/cash sales returns and consumed by customer-credit workflows.

Customer balance rules:

- Posted credit invoices increase `balance`.
- Posted customer payments decrease `balance`.
- Voided posted payments restore `balance`.
- Sales returns decrease `balance` first; any excess becomes `creditBalance`.
- Applying customer credit to an invoice decreases both `balance` and `creditBalance`.
- Refunding customer credit decreases `creditBalance`; the refund transaction clears the Accounts Receivable credit in the general ledger.

Vendor responses include:

- `balance`: current regular vendor payable balance.
- `creditBalance`: available vendor credit created by paid purchase returns and consumed by vendor-credit workflows.

Vendor balance rules:

- Posted purchase bills increase `balance`.
- Posted vendor payments decrease `balance`.
- Voided posted vendor payments restore `balance`.
- Purchase returns decrease `balance` first; any excess becomes `creditBalance`.
- Applying vendor credit to a bill decreases both `balance` and `creditBalance`.
- Receiving a vendor refund decreases `creditBalance`; the refund receipt transaction clears the Accounts Payable debit in the general ledger.

## Customers

### List Customers

```http
GET /api/customers?search=&includeInactive=false&page=1&pageSize=25
```

Response:

```json
{
  "items": [
    {
      "id": "guid",
      "displayName": "Ahmed Mohamed",
      "companyName": "Solution SA",
      "email": "ahmed@solution.sa",
      "phone": "+966 123 50 4567",
      "currency": "EGP",
      "balance": 12450,
      "isActive": true
    }
  ],
  "totalCount": 1,
  "page": 1,
  "pageSize": 25
}
```

### Get Customer

```http
GET /api/customers/{id}
```

### Create Customer

```http
POST /api/customers
Content-Type: application/json
```

```json
{
  "displayName": "New Customer",
  "companyName": "Company LLC",
  "email": "customer@example.com",
  "phone": "01000000000",
  "currency": "EGP",
  "openingBalance": 0
}
```

Validation:

- `displayName` is required and must be unique.
- `email`, when supplied, must be a valid email and unique.
- `openingBalance` cannot be negative.

Accounting:

- If `openingBalance` is greater than zero, the API creates an opening balance transaction.
- Debit Accounts Receivable.
- Credit Equity.
- The transaction uses `sourceEntityType=CustomerOpeningBalance`.

### Update Customer

```http
PUT /api/customers/{id}
```

```json
{
  "displayName": "Updated Customer",
  "companyName": "Company LLC",
  "email": "customer@example.com",
  "phone": "01000000000",
  "currency": "EGP"
}
```

### Activate / Deactivate Customer

```http
PATCH /api/customers/{id}/active
```

```json
{
  "isActive": false
}
```

## Vendors

Vendors are the supplier foundation for purchase bills, receiving inventory, and Accounts Payable workflows.

### List Vendors

```http
GET /api/vendors?search=&includeInactive=false&page=1&pageSize=25
```

Response:

```json
{
  "items": [
    {
      "id": "guid",
      "displayName": "Cairo Office Supplies",
      "companyName": "Cairo Office Supplies LLC",
      "email": "orders@cairo-office.example",
      "phone": "+20 100 111 2222",
      "currency": "EGP",
      "balance": 0,
      "isActive": true
    }
  ],
  "totalCount": 1,
  "page": 1,
  "pageSize": 25
}
```

### Get Vendor

```http
GET /api/vendors/{id}
```

### Create Vendor

```http
POST /api/vendors
Content-Type: application/json
```

```json
{
  "displayName": "New Vendor",
  "companyName": "Vendor LLC",
  "email": "vendor@example.com",
  "phone": "01000000000",
  "currency": "EGP",
  "openingBalance": 0
}
```

Validation:

- `displayName` is required and must be unique.
- `email`, when supplied, must be a valid email and unique.
- `openingBalance` cannot be negative.

Accounting:

- If `openingBalance` is greater than zero, the API creates an opening balance transaction.
- Debit Equity.
- Credit Accounts Payable.
- The transaction uses `sourceEntityType=VendorOpeningBalance`.

### Update Vendor

```http
PUT /api/vendors/{id}
```

```json
{
  "displayName": "Updated Vendor",
  "companyName": "Vendor LLC",
  "email": "vendor@example.com",
  "phone": "01000000000",
  "currency": "EGP"
}
```

### Activate / Deactivate Vendor

```http
PATCH /api/vendors/{id}/active
```

```json
{
  "isActive": false
}
```

## Purchase Bills

Purchase bills are posted through a dedicated posting service. Posted purchase bills:

- Debit Inventory Asset for inventory items.
- Debit the item expense account for service/non-inventory items.
- Credit Accounts Payable.
- Increase inventory item quantity on hand.
- Increase vendor balance.

### List Purchase Bills

```http
GET /api/purchase-bills?search=&vendorId=&includeVoid=false&page=1&pageSize=25
```

### Get Purchase Bill

```http
GET /api/purchase-bills/{id}
```

### Create Purchase Bill

```http
POST /api/purchase-bills
Content-Type: application/json
```

```json
{
  "vendorId": "guid",
  "billDate": "2026-04-18",
  "dueDate": "2026-05-18",
  "saveMode": 2,
  "lines": [
    {
      "itemId": "guid",
      "description": "Line description",
      "quantity": 2,
      "unitCost": 40
    }
  ]
}
```

If `unitCost` is `0`, the API uses the selected item's purchase price.

`saveMode` is numeric:

```text
1 Draft
2 SaveAndPost
```

Validation:

- `vendorId` must point to an active vendor.
- Bills must have at least one line.
- `quantity` must be greater than zero.
- `unitCost` cannot be negative.
- Inventory items need an inventory asset account before posting.
- Service/non-inventory items need an expense account before posting.
- Accounts Payable must exist before posting.

### Post Purchase Bill

```http
POST /api/purchase-bills/{id}/post
```

Posting is idempotent; posting an already posted purchase bill returns the existing posted bill instead of creating duplicate accounting or inventory effects.

Purchase bill transactions use:

```text
sourceEntityType=PurchaseBill
sourceEntityId={purchaseBillId}
transactionType=PurchaseBill
```

### Void Purchase Bill

```http
PATCH /api/purchase-bills/{id}/void
```

Voids a purchase bill and returns the updated bill.

Rules:

- Draft bills are marked `Void` with no accounting or inventory impact.
- Posted bills create a balanced reversal transaction.
- Inventory quantities received by the posted bill are removed from stock.
- Void is blocked if current stock is lower than the quantity that must be reversed.
- Vendor balance is reduced by the bill total.
- Void is idempotent; calling it more than once does not duplicate reversal transactions, inventory movements, or vendor balance changes.

Purchase bill reversal transactions use:

```text
sourceEntityType=PurchaseBillReversal
sourceEntityId={purchaseBillId}
transactionType=PurchaseBillReversal
```

Purchase bills with applied vendor payments cannot be voided directly. Reverse the vendor payment first, then void the purchase bill.

## Purchase Returns

Purchase returns are posted as independent vendor credit documents against posted purchase bills. They are not the same as voiding a bill.

Posting a purchase return:

- Debits Accounts Payable for the return total.
- Credits Inventory Asset for returned inventory items.
- Credits the item expense account for returned service/non-inventory items.
- Decreases inventory item quantity on hand by returned quantity.
- Increases the purchase bill `returnedAmount`.
- Reduces the bill `balanceDue` down to zero.
- If the bill has already been paid beyond the remaining bill balance, the excess becomes vendor `creditBalance`.

### List Purchase Returns

```http
GET /api/purchase-returns?search=&purchaseBillId=&vendorId=&includeVoid=false&page=1&pageSize=25
```

### Get Purchase Return

```http
GET /api/purchase-returns/{id}
```

### Create Purchase Return

```http
POST /api/purchase-returns
Content-Type: application/json
```

```json
{
  "purchaseBillId": "guid",
  "returnDate": "2026-04-18",
  "lines": [
    {
      "purchaseBillLineId": "guid",
      "quantity": 1,
      "unitCost": 50
    }
  ]
}
```

If `unitCost` is `null` or `0`, the API uses the original purchase bill line unit cost.

Validation:

- `purchaseBillId` must point to a posted/paid/partially-paid purchase bill.
- Draft and void bills cannot be returned.
- At least one return line is required.
- Each return line must reference an existing line from the selected purchase bill.
- Returned item must match the original bill line item.
- Return quantity cannot exceed the original purchased quantity minus quantities already returned by posted purchase returns.
- Inventory returns are blocked if current stock on hand is lower than the quantity being returned.
- Returned items must still have the same accounting links required by purchase bill posting.

Purchase return transactions use:

```text
sourceEntityType=PurchaseReturn
sourceEntityId={purchaseReturnId}
transactionType=PurchaseReturn
```

## Vendor Credits

Vendor credits are created automatically when a purchase return exceeds the purchase bill balance due, such as returning goods from a fully paid vendor bill.

Vendor credit workflows:

- Apply vendor credit to another purchase bill.
- Receive a vendor refund into a Bank or Other Current Asset account.

Applying vendor credit to a bill is a vendor subledger allocation. It reduces vendor `creditBalance`, increases the target bill `creditAppliedAmount`, and reduces `balanceDue`. It does not create a new general-ledger transaction because the original purchase return already debited Accounts Payable.

Receiving a refund creates a general-ledger transaction:

- Debit selected bank/cash account.
- Credit Accounts Payable.
- Reduce vendor `creditBalance`.

### List Vendor Credit Activities

```http
GET /api/vendor-credits?search=&vendorId=&action=&includeVoid=false&page=1&pageSize=25
```

`action` is numeric:

```text
1 ApplyToBill
2 RefundReceipt
```

### Get Vendor Credit Activity

```http
GET /api/vendor-credits/{id}
```

### Create Vendor Credit Activity

```http
POST /api/vendor-credits
Content-Type: application/json
```

Apply credit to bill:

```json
{
  "vendorId": "guid",
  "activityDate": "2026-04-18",
  "amount": 60,
  "action": 1,
  "purchaseBillId": "guid",
  "depositAccountId": null,
  "paymentMethod": null
}
```

Receive refund:

```json
{
  "vendorId": "guid",
  "activityDate": "2026-04-18",
  "amount": 40,
  "action": 2,
  "purchaseBillId": null,
  "depositAccountId": "guid",
  "paymentMethod": "Cash"
}
```

Validation:

- `vendorId` must point to an existing vendor.
- `amount` must be greater than zero.
- `amount` cannot exceed vendor `creditBalance`.
- Applying credit requires a purchase bill for the same vendor.
- Applying credit cannot exceed the target bill `balanceDue`.
- Refund receipts require `depositAccountId`.
- Deposit account must be Bank or Other Current Asset.

Refund receipt transactions use:

```text
sourceEntityType=VendorCreditRefund
sourceEntityId={vendorCreditActivityId}
transactionType=VendorCreditRefund
```

## Vendor Payments

Vendor payments are auto-posted after creation. They create a balanced accounting transaction:

- Debit Accounts Payable.
- Credit selected bank/cash account.
- Apply the amount to the target purchase bill.
- Reduce vendor balance.
- Update purchase bill status to `PartiallyPaid` or `Paid`.

### List Vendor Payments

```http
GET /api/vendor-payments?search=&vendorId=&purchaseBillId=&includeVoid=false&page=1&pageSize=25
```

### Get Vendor Payment

```http
GET /api/vendor-payments/{id}
```

### Pay Vendor

```http
POST /api/vendor-payments
Content-Type: application/json
```

```json
{
  "purchaseBillId": "guid",
  "paymentAccountId": "guid",
  "paymentDate": "2026-04-18",
  "amount": 100,
  "paymentMethod": "Cash"
}
```

Validation:

- `purchaseBillId` must point to an existing posted or partially paid purchase bill.
- `amount` must be greater than zero.
- `amount` cannot exceed purchase bill balance due.
- `paymentAccountId` must point to a Bank or Other Current Asset account.
- Accounts Payable must exist.

Vendor payment transactions use:

```text
sourceEntityType=VendorPayment
sourceEntityId={vendorPaymentId}
transactionType=VendorPayment
```

### Void Vendor Payment

```http
PATCH /api/vendor-payments/{id}/void
```

Voids a vendor payment and returns the updated payment.

Rules:

- Posted vendor payments create a balanced reversal transaction.
- The purchase bill paid amount is reduced by the payment amount.
- Purchase bill status returns to `Posted` when no payments remain, or `PartiallyPaid` when some payment remains.
- Vendor balance is increased by the payment amount.
- Void is idempotent; calling it more than once does not duplicate reversal transactions or change balances twice.

Vendor payment reversal transactions use:

```text
sourceEntityType=VendorPaymentReversal
sourceEntityId={vendorPaymentId}
transactionType=VendorPaymentReversal
```

## Accounts

Account responses include `balance`. It is calculated from posted accounting transactions:

- Asset and expense accounts use debit minus credit.
- Liability, equity, and income accounts use credit minus debit.
- Posting an invoice should increase Accounts Receivable and Sales Income.
- Inventory invoices should also increase COGS and decrease Inventory Asset.

### List Accounts

```http
GET /api/accounts?search=&accountType=&includeInactive=false&page=1&pageSize=100
```

`accountType` is numeric:

```text
1 Bank
2 AccountsReceivable
3 OtherCurrentAsset
4 InventoryAsset
5 FixedAsset
6 AccountsPayable
7 CreditCard
8 OtherCurrentLiability
9 LongTermLiability
10 Equity
11 Income
12 OtherIncome
13 CostOfGoodsSold
14 Expense
15 OtherExpense
```

### Create Account

```http
POST /api/accounts
```

```json
{
  "code": "4000",
  "name": "Sales Income",
  "accountType": 11,
  "description": "Sales revenue",
  "parentId": null
}
```

Validation:

- `code` is required and must be unique.
- `name` is required and must be unique.
- `parentId`, when supplied, must point to an existing account.

### Update Account

```http
PUT /api/accounts/{id}
```

## MAUI Entry Routes

Current MAUI entry screens are separate from list screens:

```text
/accounts/new
/accounts/{id}/edit
/customers/new
/customers/{id}/edit
/items/new
/items/{id}/edit
/inventory-adjustments/new
/invoices/new
```

### Activate / Deactivate Account

```http
PATCH /api/accounts/{id}/active
```

```json
{
  "isActive": true
}
```

## Items

### List Items

```http
GET /api/items?search=&includeInactive=false&page=1&pageSize=25
```

`itemType` is numeric:

```text
1 Inventory
2 NonInventory
3 Service
4 Bundle
```

### Create Item

```http
POST /api/items
```

```json
{
  "name": "Receipt Printer",
  "itemType": 1,
  "sku": "INV-PRN-001",
  "barcode": "622100000001",
  "salesPrice": 4200,
  "purchasePrice": 3100,
  "quantityOnHand": 12,
  "unit": "pcs",
  "incomeAccountId": "guid-or-null",
  "inventoryAssetAccountId": "guid-or-null",
  "cogsAccountId": "guid-or-null",
  "expenseAccountId": "guid-or-null"
}
```

Account IDs are optional today, but if supplied they must point to existing accounts.

Validation:

- `name` is required and must be unique.
- `sku`, when supplied, must be unique.
- `barcode`, when supplied, must be unique.
- `salesPrice`, `purchasePrice`, and `quantityOnHand` cannot be negative.

Accounting:

- For inventory items, if `quantityOnHand` and `purchasePrice` are greater than zero, the API creates an opening inventory transaction.
- Debit Inventory Asset for `quantityOnHand * purchasePrice`.
- Credit Equity for the same amount.
- Opening inventory quantity requires `inventoryAssetAccountId`.
- The transaction uses `sourceEntityType=ItemOpeningBalance`.

### Update Item

```http
PUT /api/items/{id}
```

### Adjust Item Quantity

```http
PATCH /api/items/{id}/quantity
```

```json
{
  "quantityOnHand": 10
}
```

### Activate / Deactivate Item

```http
PATCH /api/items/{id}/active
```

## Inventory Adjustments

Inventory adjustments are used for stock count corrections, shrinkage, damage, and found stock.

Current behavior:

- The API saves the adjustment document and auto-posts it immediately.
- Posting creates inventory movement and a balanced accounting transaction.
- Invalid negative stock adjustments are rejected before saving the adjustment document.

### List Inventory Adjustments

```http
GET /api/inventory-adjustments?search=&itemId=&includeVoid=false&page=1&pageSize=25
```

### Get Inventory Adjustment

```http
GET /api/inventory-adjustments/{id}
```

### Create Inventory Adjustment

```http
POST /api/inventory-adjustments
Content-Type: application/json
```

```json
{
  "itemId": "guid",
  "adjustmentAccountId": "guid",
  "adjustmentDate": "2026-04-18",
  "quantityChange": -2,
  "unitCost": 20,
  "reason": "Damaged stock"
}
```

Rules:

- `quantityChange` cannot be zero.
- Positive `quantityChange` increases stock.
- Negative `quantityChange` decreases stock.
- Only inventory items can be adjusted.
- Inventory items must have an inventory asset account before adjustment.
- Negative adjustments cannot reduce quantity on hand below zero.
- If `unitCost` is missing or zero, the API uses the item purchase price.
- Unit cost must be greater than zero after fallback.
- `adjustmentAccountId` must be an Expense, Cost of Goods Sold, Other Expense, Income, or Other Income account.

Accounting:

- Positive adjustment:
  - Debit Inventory Asset.
  - Credit the selected adjustment account.
- Negative adjustment:
  - Debit the selected adjustment account.
  - Credit Inventory Asset.
- The transaction uses `sourceEntityType=InventoryAdjustment`.
- Posting is idempotent by source adjustment.

## Invoices

### List Invoices

```http
GET /api/invoices?search=&customerId=&includeVoid=false&page=1&pageSize=25
```

### Create Invoice

```http
POST /api/invoices
```

```json
{
  "customerId": "guid",
  "invoiceDate": "2026-04-17",
  "dueDate": "2026-05-17",
  "saveMode": 2,
  "paymentMode": 1,
  "depositAccountId": null,
  "paymentMethod": null,
  "lines": [
    {
      "itemId": "guid",
      "description": "Line description",
      "quantity": 2,
      "unitPrice": 100,
      "discountPercent": 0
    }
  ]
}
```

If `unitPrice` is `0`, the API uses the selected item's sales price.

`saveMode` is numeric:

```text
1 Draft
2 SaveAndPost
```

If `saveMode` is omitted, the API defaults to `SaveAndPost` for daily sales behavior.

`paymentMode` is numeric:

```text
1 Credit
2 Cash
```

Cash invoice behavior:

- Cash invoices require `depositAccountId`.
- The deposit account must be a Bank or Other Current Asset account.
- When a cash invoice is saved and posted, the API posts the invoice first, then auto-creates and posts a customer payment for the remaining invoice balance.
- The generated receipt payment uses `paymentNumber=RCPT-{invoiceNumber}`.
- The invoice response includes `paymentMode`, `depositAccountId`, `depositAccountName`, `paymentMethod`, and `receiptPaymentId`.
- Cash invoices normally return as `Paid` with `balanceDue=0`.

Validation:

- `customerId` must point to an existing customer.
- Invoices must have at least one line.
- `quantity` must be greater than zero.
- `unitPrice` cannot be negative.
- `discountPercent` must be between 0 and 100.

### Mark Invoice Sent

```http
PATCH /api/invoices/{id}/sent
```

### Post Invoice

```http
POST /api/invoices/{id}/post
```

Creates a balanced accounting transaction and applies inventory effects. Posting is idempotent; posting an already posted invoice returns the existing posted invoice instead of creating duplicate effects.

Current posting rules:

- Debit Accounts Receivable for invoice total.
- Credit each line item's income account for line total.
- For inventory items:
  - Debit COGS using `purchasePrice * quantity`.
  - Credit Inventory Asset using `purchasePrice * quantity`.
  - Decrease item quantity on hand by sold quantity.

Required before posting:

- At least one active Accounts Receivable account exists.
- Every invoice item has an income account.
- Inventory items also need inventory asset and COGS accounts.
- Inventory items must have enough quantity on hand.

For cash invoices, the `POST /api/invoices/{id}/post` workflow also creates the linked customer payment if it has not already been created. This keeps posting idempotent and avoids duplicate receipt payments.

### Void Invoice

```http
PATCH /api/invoices/{id}/void
```

Voids an invoice and returns the updated invoice.

Rules:

- Draft or unposted invoices are marked `Void` with no accounting transaction.
- Posted invoices create a balanced reversal transaction.
- Inventory quantities sold by the posted invoice are returned.
- Void is idempotent; calling it more than once does not create duplicate reversal transactions or return stock twice.
- The invoice response includes:
  - `postedTransactionId`
  - `postedAt`
  - `reversalTransactionId`
  - `voidedAt`

Posted invoice reversal transactions use:

```text
sourceEntityType=InvoiceReversal
sourceEntityId={invoiceId}
transactionType=InvoiceReversal
```

Invoices with applied payments cannot be voided directly. Reverse the payment first, then void the invoice.

## Sales Returns

Sales returns are posted as independent credit memo documents against posted invoices. They are not the same as voiding an invoice.

Posting a sales return:

- Debits each returned item's income account.
- Credits Accounts Receivable for the return total.
- For inventory items:
  - Debits Inventory Asset using `purchasePrice * returnedQuantity`.
  - Credits COGS using `purchasePrice * returnedQuantity`.
  - Increases item quantity on hand by returned quantity.
- Increases the invoice `returnedAmount`.
- Reduces the invoice `balanceDue`; paid invoices can create customer credit that can be applied or refunded through Customer Credits.
- If the return amount is greater than the invoice balance before the return, the excess becomes customer `creditBalance`.

### List Sales Returns

```http
GET /api/sales-returns?search=&invoiceId=&customerId=&includeVoid=false&page=1&pageSize=25
```

### Get Sales Return

```http
GET /api/sales-returns/{id}
```

### Create Sales Return

```http
POST /api/sales-returns
Content-Type: application/json
```

```json
{
  "invoiceId": "guid",
  "returnDate": "2026-04-18",
  "lines": [
    {
      "invoiceLineId": "guid",
      "quantity": 1,
      "unitPrice": 100,
      "discountPercent": 0
    }
  ]
}
```

If `unitPrice` is `null` or `0`, the API uses the original invoice line unit price.

Validation:

- `invoiceId` must point to a posted/paid/partially-paid invoice.
- Draft and void invoices cannot be returned.
- At least one return line is required.
- Each return line must reference an existing invoice line from the selected invoice.
- Returned item must match the original invoice line item.
- Return quantity cannot exceed the original sold quantity minus quantities already returned by posted sales returns.
- Returned items must still have the same accounting links required by invoice posting.

Sales return transactions use:

```text
sourceEntityType=SalesReturn
sourceEntityId={salesReturnId}
transactionType=SalesReturn
```

## Customer Credits

Customer credits are created automatically when a sales return exceeds the invoice balance due, such as returning a fully-paid cash invoice.

Customer credit workflows:

- Apply customer credit to another invoice.
- Refund customer credit through a Bank or Other Current Asset account.

Applying credit to an invoice is a customer subledger allocation. It reduces customer `creditBalance`, increases the target invoice `creditAppliedAmount`, and reduces `balanceDue`. It does not create a new general-ledger transaction because the original sales return already credited Accounts Receivable.

Refunding credit creates a general-ledger transaction:

- Debit Accounts Receivable.
- Credit selected bank/cash account.
- Reduce customer `creditBalance`.

### List Customer Credit Activities

```http
GET /api/customer-credits?search=&customerId=&action=&includeVoid=false&page=1&pageSize=25
```

`action` is numeric:

```text
1 ApplyToInvoice
2 Refund
```

### Get Customer Credit Activity

```http
GET /api/customer-credits/{id}
```

### Create Customer Credit Activity

```http
POST /api/customer-credits
Content-Type: application/json
```

Apply credit to invoice:

```json
{
  "customerId": "guid",
  "activityDate": "2026-04-18",
  "amount": 60,
  "action": 1,
  "invoiceId": "guid",
  "refundAccountId": null,
  "paymentMethod": null
}
```

Refund credit:

```json
{
  "customerId": "guid",
  "activityDate": "2026-04-18",
  "amount": 40,
  "action": 2,
  "invoiceId": null,
  "refundAccountId": "guid",
  "paymentMethod": "Cash"
}
```

Validation:

- `customerId` must point to an existing customer.
- `amount` must be greater than zero.
- `amount` cannot exceed customer `creditBalance`.
- Applying credit requires an invoice for the same customer.
- Applying credit cannot exceed the target invoice `balanceDue`.
- Refunds require `refundAccountId`.
- Refund account must be Bank or Other Current Asset.

Refund transactions use:

```text
sourceEntityType=CustomerCreditRefund
sourceEntityId={customerCreditActivityId}
transactionType=CustomerCreditRefund
```

## Payments

Payments are auto-posted after creation. They create a balanced accounting transaction:

- Debit selected bank/cash account.
- Credit Accounts Receivable.
- Apply the amount to the target invoice.
- Update invoice status to `PartiallyPaid` or `Paid`.

### List Payments

```http
GET /api/payments?search=&customerId=&invoiceId=&includeVoid=false&page=1&pageSize=25
```

### Get Payment

```http
GET /api/payments/{id}
```

### Receive Payment

```http
POST /api/payments
Content-Type: application/json
```

```json
{
  "invoiceId": "guid",
  "depositAccountId": "guid",
  "paymentDate": "2026-04-18",
  "amount": 100,
  "paymentMethod": "Cash"
}
```

Validation:

- `invoiceId` must point to an existing posted or partially paid invoice.
- `amount` must be greater than zero.
- `amount` cannot exceed invoice balance due.
- `depositAccountId` must point to a Bank or Other Current Asset account.
- Accounts Receivable must exist.

Payment transactions use:

```text
sourceEntityType=Payment
sourceEntityId={paymentId}
transactionType=Payment
```

### Void Payment

```http
PATCH /api/payments/{id}/void
```

Voids a payment and returns the updated payment.

Rules:

- Posted payments create a balanced reversal transaction.
- The target invoice paid amount is reduced by the payment amount.
- Invoice status returns to `Posted` when no payments remain, or `PartiallyPaid` when some payment remains.
- Void is idempotent; calling it more than once does not duplicate reversal transactions or reduce paid amount twice.

Payment reversal transactions use:

```text
sourceEntityType=PaymentReversal
sourceEntityId={paymentId}
transactionType=PaymentReversal
```

## Transactions

The MAUI app has a read-only Transactions screen at:

```text
/transactions
```

### List Transactions

```http
GET /api/transactions?search=&sourceEntityType=&sourceEntityId=&includeVoided=false&page=1&pageSize=50
```

### Get Transaction

```http
GET /api/transactions/{id}
```

Transactions are currently read-only from the API. They are created by posting workflows.
