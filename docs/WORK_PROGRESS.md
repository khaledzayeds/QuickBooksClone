# LedgerFlow / QuickBooksClone — Work Progress Tracker

> الملف ده هو سجل التقدم العملي للمشروع.  
> أي شغل يتم، أو قرار يتاخد، أو حاجة تتأجل، تتسجل هنا عشان نعرف إحنا واقفين فين.

Branch: `local-update`

---

## Current Working Strategy

```text
A) Stability / Build Lock
   ↓
B) Settings + Setup Wizard + Connection
   ↓
C) Core MVP Polish
   ↓
D) Printing + Reports + Backup
   ↓
E) Licensing + Installer
   ↓
F) Banking / Inventory Pro / Payroll
```

---

## Working Rules

1. أي تعديل كبير يتسجل هنا.
2. أي route جديد لازم يتسجل في `AppRoutes`، ومش يبقى hardcoded جوه الشاشة.
3. أي feature غير مكتملة إما تتخفى أو تفتح `Coming Soon` واضح، مش ترجع للداشبورد.
4. أي شاشة تجارية لازم يكون فيها Loading/Error/Empty states و Search/filter لو List screen.
5. أي نص ظاهر للمستخدم لازم يتحول لاحقًا إلى localization.
6. أي transaction مالية لازم يكون لها status واضح: Draft / Saved / Posted / Voided.
7. أي posted transaction لازم يكون لها void/reversal strategy.
8. أي ميزة مدفوعة أو مرتبطة بنسخة معينة لازم تعدي من License Gate أو Feature Flag واضح.
9. أي private signing key لازم يفضل خارج تطبيق العميل تمامًا.
10. Restore operations must create or offer safety backup before overwriting live company data.
11. First-run setup must not overwrite an already initialized company.
12. Default account seeding must be idempotent and skip existing account codes.
13. Items are not all inventory. Item types must be separated by posting behavior: stock, service, non-stock, bundle/group, document-calculation items, tax items, and advanced assembly/fixed asset items.
14. During fast UI polish, temporary hardcoded English text is allowed, but every polished screen must later pass through localization cleanup using the existing localization files.
15. Transaction screens must be keyboard-first and scanner-friendly, not mouse-only forms.
16. Transaction screens must have preview, print, save, post, and clear status behavior planned from the first UI pass.
17. Transaction screens should support a collapsible context side panel for customer/vendor/item/account history and balances.
18. Build full QuickBooks-style transaction screens first. POS/cart/mobile fast screens come later as separate UIs over the same backend and reusable transaction components.

---

## Transaction Screen UX Standards

### Status

`Invoice shell wiring started`

### Product Decision

Start with full accounting transaction screens first, not cart-only screens. The first sales and purchase screens should be QuickBooks-style full screens with all important accounting controls visible: customer/vendor, document number, status, dates, terms, line grid, tax, discounts, totals, side context panel, preview, print, save, and post.

Fast POS/cart/mobile screens are still planned, but they should be built later as separate modes using the same backend and reusable transaction components. They must not replace the full accounting screen.

### Reusable Transaction Widgets Started

- [x] `transaction_models.dart`
- [x] `transaction_header_panel.dart`
- [x] `transaction_party_selector.dart`
- [x] `transaction_line_grid.dart`
- [x] `transaction_totals_footer.dart`
- [x] `transaction_print_menu.dart`
- [x] `transaction_action_bar.dart`
- [x] `transaction_context_side_panel.dart`
- [x] `transaction_keyboard_shortcuts.dart`

### Invoice Shell Wiring Started

- [x] `InvoiceFormPage` now uses reusable transaction shell widgets:
  - `TransactionKeyboardShortcuts`
  - `TransactionHeaderPanel`
  - `TransactionPartySelector`
  - `TransactionTotalsFooter`
  - `TransactionContextSidePanel`
  - `TransactionActionBar`
- [x] Preserved the existing legacy `TransactionLineTable` temporarily so item selection and save flow remain functional while the new scanner-first grid is developed.
- [x] Added full accounting mode layout with:
  - Document number/date/due date/terms/reference header.
  - Customer selector shell with balance and credit chips.
  - Collapsible customer context side panel.
  - Save Draft / Save / Post / Print / Clear action bar.
  - Keyboard shortcut shell callbacks.
- [x] Added placeholders for:
  - F4 barcode focus.
  - F5 previous quantity correction.
  - F7 item lookup.
  - Print service wiring.

### Still Needed Before Invoice Screen Is Final

- [ ] Replace legacy line table with the new editable/scanner-first `TransactionLineGrid` or bridge it safely to existing `TransactionLineEntry` logic.
- [ ] Wire shortcut callbacks into real focus nodes/cell navigation.
- [ ] Build lightweight item lookup popup under active grid cell.
- [ ] Connect real customer/item repositories to invoice screen with fast search.
- [ ] Add invoice/sales receipt form state provider.
- [ ] Add print preview service integration.
- [ ] Wire `SalesReceiptFormPage` to the same transaction shell pattern.

### Implementation Direction

- Build reusable transaction widgets before polishing every screen separately.
- Do not duplicate keyboard/grid logic separately for invoices, bills, purchase orders, and receipts.
- First real consumers are full accounting Invoice / Sales Receipt screens.

---

## Phase C — Core MVP Polish

### Status

`Started`

### Goal

تحويل الموديولات الأساسية إلى نسخة قابلة للبيع.

### Modules

- [x] Customers
- [x] Vendors
- [ ] Items
- [x] Chart of Accounts
- [ ] Invoices
- [ ] Sales Receipts
- [ ] Payments
- [ ] Purchase Orders
- [ ] Receive Inventory
- [ ] Purchase Bills
- [ ] Vendor Payments
- [ ] Sales Returns
- [ ] Purchase Returns
- [ ] Customer Credits
- [ ] Vendor Credits
- [ ] Inventory Adjustments
- [ ] Journal Entries
- [ ] Reports

### Next Recommended Phase C Order

1. Continue Invoice full accounting screen wiring.
2. Wire Sales Receipt full accounting screen to the same shell.
3. Replace/bridge the line grid with scanner-first behavior.
4. Purchase Orders / Bills / Receive Inventory full accounting screens.
5. Payments / Vendor Payments.
6. Sales/Purchase returns and credits polish.
7. Reports polish.
8. POS/cart/mobile fast screens after full screens stabilize.

---

## Latest Progress Log

### 2026-05-04

- Added roadmap, progress tracker, and local verification checklist.
- Completed Phase B core setup/licensing/backup/users/settings work.
- Added Post Phase B Polish Backlog with password UI, audit log, device limits, user-limit enforcement, and backup import timing.
- Added Localization Cleanup Backlog to migrate temporary hardcoded UI strings into existing localization files after screens stabilize.
- Started Phase C Core MVP Polish.
- Polished Chart of Accounts backend/frontend flow and fixed account datasource/toggle mismatches.
- Completed first Items polish pass: backend item rules, item account selectors, Inventory Center style list, item card metrics, and item details view.
- Completed first Customers polish pass: backend active toggle fix, Customer Center list, card metrics, form polish, and details view.
- Completed first Vendors polish pass: backend active toggle fix, Vendor Center list, card metrics, form polish, and details view.
- Added Transaction Screen UX Standards covering scanner support, keyboard shortcuts, fast grids, collapsible context side panels, preview/print actions, and save/post behavior before starting invoice/purchase screen polish.
- Confirmed product decision: build full QuickBooks-style transaction screens first, then POS/cart/mobile fast screens later over the same backend and reusable transaction components.
- Added first reusable transaction widget foundation for header, party selector, line grid, totals footer, action bar, print menu, context side panel, and keyboard shortcuts.
- Wired InvoiceFormPage to the new transaction shell while preserving the existing legacy line table temporarily to avoid breaking the current save flow.
- Next focus: continue invoice shell polish, wire SalesReceiptFormPage, then replace/bridge the line grid with scanner-first behavior.
