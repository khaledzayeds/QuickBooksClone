# Frontend Integration Guide

This guide is the practical contract for testing the backend from another frontend such as Windows Forms now or Flutter later.

Base URL:

```text
http://localhost:5014
```

Primary runtime model:

```text
Blazor/WinForms/Flutter client -> Local API -> SQLite
```

Future sync target:

```text
Local API/SQLite -> Sync Layer -> Central SQL Server
```

Current sync diagnostics before the sync engine ships:

- `GET /api/sync/overview`
- `GET /api/sync/documents`
- `POST /api/sync/documents/{documentType}/{id}/mark-pending`

## 1. Runtime Check First

Always begin with:

```http
GET /api/settings/runtime
```

Use it to confirm:

- API is running
- provider is `Sqlite` or `SqlServer`
- backup support is available
- the active local database path

## 2. Core Reference Data

Before workflows, load the basic masters:

- `GET /api/accounts`
- `GET /api/customers`
- `GET /api/vendors`
- `GET /api/items`

These endpoints are the foundation for dropdowns and document creation.

## 3. Purchase Flow

Recommended client order:

1. Create or search purchase orders
   - `GET /api/purchase-orders`
   - `POST /api/purchase-orders`
2. Ask the backend what can still be received
   - `GET /api/purchase-orders/{id}/receiving-plan`
3. Create receipt from the plan
   - `POST /api/receive-inventory`
4. Ask the backend what can still be billed
   - `GET /api/receive-inventory/{id}/billing-plan`
5. Create bill from the plan
   - `POST /api/purchase-bills`
6. Ask the backend what can still be paid
   - `GET /api/purchase-bills/{id}/payment-plan`
7. Pay the bill
   - `POST /api/vendor-payments`

Important rule:

- Do not let the frontend guess remaining quantities.
- Always use the plan endpoints before downstream conversion.

## 4. Sales Flow

Recommended client order:

1. Create or search estimates
   - `GET /api/estimates`
   - `POST /api/estimates`
2. Ask the backend what can still be converted into sales order
   - `GET /api/estimates/{id}/sales-order-plan`
3. Convert estimate to sales order
   - `POST /api/estimates/{id}/convert-to-sales-order`
4. Ask the backend what can still be invoiced
   - `GET /api/sales-orders/{id}/invoice-plan`
5. Convert sales order to invoice
   - `POST /api/sales-orders/{id}/convert-to-invoice`
6. Ask the backend what can still be paid
   - `GET /api/invoices/{id}/payment-plan`
7. Receive payment
   - `POST /api/payments`

Important rule:

- The frontend should not compute partial conversion quantities itself.
- The API is the source of truth for ordered, invoiced, paid, and remaining values.

## 5. Posting vs Non-Posting Summary

Non-posting documents:

- Estimate
- Sales Order
- Purchase Order

Posting documents:

- Invoice
- Sales Receipt
- Receive Payment
- Receive Inventory
- Purchase Bill
- Vendor Payment
- Returns / Credits / Adjustments / Journal Entries

## 6. Status Expectations

The frontend should treat status values as domain state, not visual labels only.

Examples:

- Purchase Order: `Draft`, `Open`, `Closed`, `Cancelled`
- Sales Order: `Draft`, `Open`, `Closed`, `Cancelled`
- Estimate: `Draft`, `Sent`, `Accepted`, `Declined`, `Cancelled`
- Invoice: `Draft`, `Sent`, `Posted`, `PartiallyPaid`, `Paid`, `Returned`, `Void`
- Purchase Bill: `Draft`, `Posted`, `PartiallyPaid`, `Paid`, `Returned`, `Void`

The UI may localize these labels, but must not reinterpret the business meaning.

## 7. Validation and Error Handling

Current API behavior:

- Validation and business-rule failures return `400 Bad Request`
- missing entities return `404 Not Found`
- duplicate business keys return `409 Conflict`

Recommended frontend behavior:

- show the response text/message directly during testing
- do not replace backend business errors with generic UI messages
- keep the full response body/log available during Windows Forms testing

## 8. Stable DTO Expectations

Current DTOs are intended to be frontend-agnostic.

The frontend should rely on:

- explicit ids
- explicit status values
- backend-calculated totals
- backend-calculated balances
- backend-calculated remaining quantities
- linked document ids/numbers when exposed

The frontend should avoid:

- recalculating workflow remaining quantities
- assuming document relationships that the API does not expose
- embedding accounting rules in the client

## 9. Best Smoke Tests Before Trying a New Frontend

Run this first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\smoke-core-backend.ps1
```

If this passes, the backend core is in a good state for another frontend to exercise.

## 10. Most Important Endpoints For UI Builders

If building a new frontend, start from these:

- `GET /api/settings/runtime`
- `GET /api/accounts`
- `GET /api/customers`
- `GET /api/vendors`
- `GET /api/items`
- `GET /api/purchase-orders/{id}/receiving-plan`
- `GET /api/receive-inventory/{id}/billing-plan`
- `GET /api/purchase-bills/{id}/payment-plan`
- `GET /api/estimates/{id}/sales-order-plan`
- `GET /api/sales-orders/{id}/invoice-plan`
- `GET /api/invoices/{id}/payment-plan`
- `GET /api/sync/overview`
- `GET /api/sync/documents?status=PendingSync&take=50`

These are the key workflow-intelligence endpoints that prevent frontend guesswork.
