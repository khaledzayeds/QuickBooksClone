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
