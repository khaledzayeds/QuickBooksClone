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
