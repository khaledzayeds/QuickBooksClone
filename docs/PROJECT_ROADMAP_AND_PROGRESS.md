# QuickBooks Clone / ZOKAA POS — Project Roadmap and Progress

> This document is the official working roadmap for the project. It explains what we are building, why we are building it, what has been completed, what is currently in progress, and what remains before the product becomes a professional commercial ERP/POS system.

---

## 1. Project Vision

We are building a professional QuickBooks-like ERP/POS system designed for real commercial use, not just a demo application.

The target product should support:

- Arabic and English user interface with runtime language switching.
- Desktop-first business workflow similar to QuickBooks.
- Multiple front ends connected to the same backend and database.
- Strong accounting posting logic.
- Inventory tracking.
- Sales workflow.
- Purchasing workflow.
- Vendor/customer balances.
- Banking and reconciliation.
- Reporting dashboards.
- Printing and preview services.
- Settings-driven behavior.
- Offline/local database direction with future sync capability.

The main idea is that the system should eventually become a commercial product that can be sold, customized, and used by real shops, distributors, and small/medium businesses.

---

## 2. Product Direction

The product should feel like a real accounting system, not a simple invoice app.

### Core principles

1. **QuickBooks-like workflow**
   - Documents should have real business meaning.
   - Purchase Orders are not bills.
   - Receive Inventory is not a bill.
   - Bills create vendor payable.
   - Payments reduce payable.
   - Credits reduce payable using vendor credit balance.

2. **Posting discipline**
   - Some documents may be Draft/Saved first.
   - Important financial documents should post accounting effects deliberately.
   - The system must protect accounting integrity.

3. **Multiple interfaces, one data source**
   - Main desktop app.
   - Possible Flutter app for invoices/reports/cashier.
   - Possible fast POS/cashier screens later.
   - All interfaces should talk to the same API/backend/database.

4. **Professional UI foundation first, polish later**
   - Current goal is workflow correctness.
   - Visual redesign and polish can come later because the foundation matters more.

5. **Commercial readiness**
   - Clear settings.
   - Reliable document numbers.
   - Printing service independent from screens.
   - Strong reports.
   - Backup/restore.
   - Permissions.
   - Clean error handling.

---

## 3. Architecture Direction

### Backend

Current direction:

- ASP.NET Web API.
- C# domain/core logic.
- SQL/SQLite-compatible persistence direction.
- Posting services for accounting impact.
- Repository pattern.
- DTO contracts between backend and frontend.

Important backend concepts:

- Document number service.
- Posting engine.
- Accounting transaction entries.
- Vendor/customer balance updates.
- Inventory quantity updates.
- Status transitions.

### Frontend

Current direction:

- Flutter frontend under `QuickBooksFlutter/ledgerflow`.
- Riverpod state management.
- GoRouter routing.
- Desktop-first transaction screens.
- Shared widgets for transaction tables, sidebars, vendor/customer pickers, printing settings, etc.

### Printing

Printing must be a service layer, not hardcoded inside sales screens.

Current decision:

- Printing settings belong in Settings.
- Printing should be callable from many screens.
- Sales, purchases, statements, receipts, and reports should all use shared print infrastructure.

---

## 4. Current Major Workflow Status

## 4.1 Purchase Order

Status: **Mostly completed for core workflow**

Completed:

- Create Purchase Order as Draft.
- Create Purchase Order as Open.
- Edit Draft Purchase Order.
- Open Draft Purchase Order.
- Close Purchase Order.
- Cancel Purchase Order.
- Purchase Order Details screen.
- Purchase Order List screen.
- Route for editing draft orders.
- Purchase Order can start Receive Inventory.

Important logic decisions:

- Purchase Order is a functional/organizational document.
- Purchase Order should fill data into Receive Inventory.
- Purchase Order should not force the final document to be locked exactly to PO lines.

Backend additions completed:

- Draft update methods in `PurchaseOrder` core entity.
- `PUT /api/purchase-orders/{id}` endpoint for editing draft PO.
- Update purchase order request contract.

Flutter additions completed:

- `UpdatePurchaseOrderDto`.
- Repository/datasource update call.
- Edit route `/purchases/orders/edit/:id`.
- Edit button shown only for Draft PO.
- Form supports New/Edit modes.

Remaining for PO:

- Better print/preview.
- Better memo persistence if backend contract supports it.
- More polished QuickBooks-like layout.
- Tests for edge cases.

---

## 4.2 Receive Inventory

Status: **Core workflow completed**

Completed:

- Receive Inventory standalone without PO.
- Receive Inventory from PO.
- PO fills editable receipt lines.
- Manual lines are allowed even when PO is selected.
- PO-linked lines still validate against remaining PO quantity.
- Manual lines are not forced to have PO line IDs.
- Receive Inventory Details screen improved.
- Details show Standalone vs From Purchase Order.
- Details show manual vs PO-linked lines.
- Create Bill button from receipt details.

Important logic decision:

```text
PO = source of data / organization
Item Receipt = final editable receiving document
```

Backend additions completed:

- Receive Inventory creation now allows manual lines even when a PO is selected.
- Only PO-linked lines are validated against PO remaining quantity.

Flutter additions completed:

- Receive Inventory form fills editable lines from PO receiving plan.
- User can add/delete/edit manual lines.
- User can change item in a PO-filled line, converting it to manual.
- Details screen can open Purchase Bill creation with `receiptId`.

Remaining for Receive Inventory:

- Better print/preview.
- Void workflow review in UI.
- Stronger display of linked bill status.
- More polished receipt detail page.

---

## 4.3 Purchase Bill

Status: **Core workflow completed and connected**

Completed:

- Create Purchase Bill manually.
- Create Purchase Bill from Receive Inventory.
- Bill form accepts `receiptId`.
- Bill form loads receipt automatically.
- Bill form gets Billing Plan.
- Bill form fills billable lines.
- Bill lines link to Inventory Receipt lines.
- Prevent billing more than remaining receipt quantity.
- Purchase Bill list opens details.
- Purchase Bill details screen implemented.
- Details show linked inventory receipt.
- Details show lines and totals.
- Details show Paid / Unpaid / Void / Partially Paid style states.
- Void Bill action available when allowed.
- Pay Bill action from details.
- Use Credit action from details.

Backend contract review completed:

- Backend returns `PaidAmount`.
- Flutter model was corrected to read `paidAmount` and fallback to `amountPaid`.
- Flutter model now handles status as text or number.
- Flutter model now supports `creditAppliedAmount`, `returnedAmount`, and `inventoryReceiptNumber`.

Remaining for Purchase Bill:

- Print/preview.
- Better display of payment/credit history.
- More polished linked document navigation.
- Details screen should eventually show linked payments and vendor credits.

---

## 4.4 Vendor Payment

Status: **Core workflow connected**

Completed:

- Vendor Payment form supports bill preselection.
- Purchase Bill Details opens Vendor Payment using `billId`.
- Vendor Payment form loads selected bill.
- Vendor is selected automatically.
- Open bills for vendor are loaded.
- Target bill is automatically checked.
- Payment amount defaults to Balance Due.
- Payment validates amount does not exceed bill balance.
- Refreshes Purchase Bills after saving.
- Invalidates Purchase Bill details after payment.

Backend review completed:

Vendor Payment posting does:

- Validates bill is not Draft/Void.
- Validates amount does not exceed Balance Due.
- Creates accounting entry:
  - Debit Accounts Payable.
  - Credit Bank/Cash.
- Applies payment to Purchase Bill.
- Applies payment to Vendor balance.
- Marks payment as posted.

Purchase Bill `ApplyPayment` logic:

- Increases Paid Amount.
- Sets bill to Paid when Balance Due is zero.
- Sets bill to Partially Paid when balance remains.

Void Vendor Payment:

- Creates reversal transaction.
- Reverses payment on Purchase Bill.
- Reverses payment on Vendor.
- Marks payment as void.

Remaining for Vendor Payment:

- Vendor Payment list/details review.
- Print payment voucher.
- Better account selection defaults.
- Payment history from Bill Details.

---

## 4.5 Vendor Credit / Use Credit

Status: **Core Apply Credit workflow connected**

Important business meaning:

Current Vendor Credit screen is for using existing vendor credit balance or recording vendor refund, not creating inventory returns from scratch.

Completed backend review:

ApplyToBill:

- Requires PurchaseBillId.
- Requires same Vendor.
- Rejects Draft/Void bills.
- Amount must be <= Bill Balance Due.
- Applies credit to Purchase Bill.
- Uses vendor credit balance.

RefundReceipt:

- Requires deposit account.
- Deposit account must be Bank or Other Current Asset.
- Creates accounting entry:
  - Debit Bank/Deposit Account.
  - Credit Accounts Payable.
- Uses vendor credit balance.

Completed Flutter work:

- Vendor Credit form supports `billId`.
- Form loads selected bill.
- Vendor is selected automatically.
- Bill is selected automatically.
- Amount defaults to Balance Due.
- Router passes `billId` to Vendor Credit form.
- Purchase Bill Details has Use Credit action.

Remaining for Vendor Credit:

- Vendor Credit details screen review.
- Vendor Credit list polish.
- Better explanation in UI: this uses existing credit balance.
- Add guard/display for available vendor credit balance before save.
- Print/preview credit activity.

---

## 5. Next Planned Work

The next major workflow is:

## 5.1 Purchase Returns

Why next?

Purchase Return is the real document that should handle returning goods to a vendor. It is different from simply using vendor credit.

Expected behavior:

- Select Vendor.
- Optionally select Purchase Bill or Inventory Receipt.
- Select returned items.
- Reduce inventory stock.
- Reduce payable or create vendor credit depending on design.
- Create accounting posting.
- Show return in vendor activity.

Important design decision needed:

There are two possible modes:

1. **Return against Bill**
   - Reduces payable or creates vendor credit.
   - Good when goods were already billed.

2. **Return against Receipt**
   - Reduces stock from received inventory.
   - May later affect bill or credit.

Professional direction:

Support both eventually, but start with Bill-linked return because it is clearer financially.

---

## 5.2 Vendor Details / Vendor Activity

Purpose:

Vendor screen should become a real activity center, not just vendor master data.

Expected sections:

- Vendor profile.
- Balance.
- Credit balance.
- Open bills.
- Purchase orders.
- Receive inventory documents.
- Bills.
- Payments.
- Credits.
- Returns.
- Quick actions:
  - New PO.
  - Receive Inventory.
  - Enter Bill.
  - Pay Bill.
  - Use Credit.
  - Purchase Return.

---

## 5.3 Purchases Reports

Important reports:

- Open Purchase Orders.
- Unbilled Receipts.
- Open Bills.
- A/P Aging.
- Vendor Balance Summary.
- Vendor Balance Detail.
- Purchases by Vendor.
- Purchases by Item.
- Inventory Received Not Billed.

---

## 5.4 Banking Module

Still pending.

Required screens:

- Make Deposits.
- Write Checks.
- Bank Register.
- Reconcile.
- Bank rules/import later.

Banking must connect to:

- Customer payments.
- Vendor payments.
- Deposits.
- Expenses.
- Reconciliation.

---

## 6. Commercial Product Requirements

To become a professional commercial system, the project needs more than workflows.

## 6.1 Reliability

- Strong validation.
- Clear error messages.
- No silent failures.
- Safe posting/reversal.
- Consistent statuses.
- No duplicate document numbers.
- Database backup and restore.

## 6.2 User Experience

- Desktop-first design.
- Minimal scrolling on transaction screens.
- Keyboard shortcuts.
- Barcode/scanner support in item tables.
- Enter moves to next field/line.
- Fast quantity editing.
- Side panels with customer/vendor balance and recent activity.
- Print/preview/save actions on every document.

## 6.3 Localization

- Arabic/English runtime switching.
- No hardcoded UI text long-term.
- Use localization files consistently.
- RTL support for Arabic.
- Arabic-friendly fonts in print outputs.

## 6.4 Printing

Printing should be a central service:

- Invoice print.
- Sales receipt print.
- Purchase order print.
- Receive inventory print.
- Purchase bill print.
- Payment voucher print.
- Vendor/customer statement print.
- Thermal printing support where needed.
- A4 print support.

## 6.5 Security and Permissions

Needed:

- User roles.
- Permissions per module/action.
- Audit log.
- Sensitive action confirmation.
- Permission checks in backend and UI.

## 6.6 Settings

Important settings:

- Company settings.
- Tax settings.
- Printing settings.
- Document number settings.
- Backup settings.
- License settings.
- Currency settings.
- Inventory costing settings.

## 6.7 Data and Sync Direction

Current commercial direction:

- Local-first database option.
- Backup/restore.
- Future sync to server.
- Possible multiple frontends connected to the same backend.
- Future mobile/cashier apps using same API.

---

## 7. Testing Plan Later

Full testing should happen after the main workflow plan is complete.

End-to-end purchase test:

1. Create item.
2. Create vendor.
3. Create Purchase Order as Draft.
4. Edit Draft PO.
5. Open PO.
6. Receive Inventory from PO.
7. Add manual line while receiving.
8. Create Purchase Bill from Receipt.
9. Pay part of the bill.
10. Check Partially Paid.
11. Pay remaining amount.
12. Check Paid.
13. Use Vendor Credit against another bill.
14. Void allowed documents and verify reversal.
15. Check vendor balance.
16. Check inventory quantity.
17. Check accounting transactions.

---

## 8. Current Position

We are currently after:

```text
Purchase Order
→ Receive Inventory
→ Purchase Bill
→ Vendor Payment
→ Vendor Credit / Use Credit
```

The next recommended step is:

```text
Purchase Returns
```

After Purchase Returns, review Vendor Details / Vendor Activity.

---

## 9. Important Notes

- Do not over-polish UI before workflow foundations are complete.
- Design improvements can come later.
- Keep backend contract and Flutter models aligned.
- Every financial workflow must be reviewed from backend to frontend.
- Avoid hardcoded strings long-term; move to localization gradually.
- Printing should remain reusable and settings-driven.
- The project is intended to become a commercial product, so every shortcut must eventually be replaced with robust behavior.
