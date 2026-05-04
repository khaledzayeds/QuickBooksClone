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

`Required before invoice/purchase screen polish`

### Product Decision

Start with full accounting transaction screens first, not cart-only screens. The first sales and purchase screens should be QuickBooks-style full screens with all important accounting controls visible: customer/vendor, document number, status, dates, terms, line grid, tax, discounts, totals, side context panel, preview, print, save, and post.

Fast POS/cart/mobile screens are still planned, but they should be built later as separate modes using the same backend and reusable transaction components. They must not replace the full accounting screen.

### Why

- Full screens are required for commercial accounting accuracy.
- They support invoices, terms, due dates, tax, credit, print templates, posting review, and audit behavior.
- POS/cart/mobile screens are excellent for speed, but not enough for all invoice/accounting cases.
- Building reusable transaction components now lets us reuse the same logic later in POS/cart/mobile without duplicating posting rules.

### Future Sales UI Modes

- `Accounting Invoice Mode` — full QuickBooks-style invoice/sales receipt screen.
- `Fast Cashier/POS Mode` — cart-style scanner-first screen.
- `Mobile Sales Mode` — simplified cart/order screen for mobile or sales reps.

### Goal

كل شاشة مالية تبقى سريعة ومناسبة للمحاسب والكاشير، مش مجرد فورم. المعايير دي تنطبق على:

- Invoices
- Sales Receipts
- Purchase Orders
- Receive Inventory
- Purchase Bills
- Payments
- Vendor Payments
- Returns / Credits
- Inventory Adjustments
- Journal Entries

### Layout Standard

- Header compact:
  - Transaction type.
  - Number.
  - Date.
  - Status: Draft / Saved / Posted / Voided.
  - Customer/Vendor selector.
  - Terms / due date where applicable.
- Center working area:
  - Fast item/account grid.
  - Keyboard navigation.
  - Scanner-friendly input.
  - Totals footer always visible.
- Right collapsible side panel:
  - Open/close with arrow.
  - Customer/Vendor balance.
  - Credits available.
  - Last transactions.
  - Notes/warnings.
  - Related actions.
- Bottom action bar:
  - Save Draft.
  - Save.
  - Post.
  - Preview.
  - Print A4.
  - Print Thermal where applicable.
  - Email/Share later.
  - Void/Reversal after posting.

### Scanner + Keyboard Standard

- Barcode/item search cell must accept scanner input and Enter.
- Enter after item scan/search should add/select item and move to quantity or next row based on screen mode.
- Preferred flow for speed:
  1. Focus starts in item search/barcode cell.
  2. Scan barcode or type item code/name.
  3. Enter selects the best match.
  4. If default quantity is 1, move directly to next row.
  5. If item requires quantity confirmation, move to quantity cell.
  6. Enter on quantity moves to price or next row depending settings.
- Keyboard shortcuts should be configurable later, but default proposal:
  - Enter: accept current cell / move next logical cell.
  - Ctrl+Enter: add line and jump to item cell.
  - Shift+Enter: move previous cell.
  - F2: edit current row/cell.
  - F4: focus item search/barcode cell.
  - F5: jump to previous line quantity cell for quick correction.
  - F6: jump to totals/payment panel.
  - F7: open item lookup.
  - F8: open customer/vendor side panel.
  - F9: save transaction.
  - F10: preview/print menu.
  - Ctrl+P: print.
  - Ctrl+S: save draft/save.
  - Ctrl+D: duplicate current line.
  - Ctrl+L: clear current line.
  - Esc: close lookup/side panel; second Esc asks to close transaction if unsaved.

### Better alternative to only F5

- Keep F5 as quick shortcut, but also support:
  - Arrow Up/Down inside grid.
  - Shift+Enter previous cell.
  - Click/tap any row for manual edit.
  - Row number gutter on the left to select/edit/delete lines quickly.
  - Ctrl+Up / Ctrl+Down to jump between transaction lines.

### Implementation Direction

- Build reusable transaction widgets before polishing every screen separately:
  - `TransactionHeaderPanel`
  - `TransactionPartySelector`
  - `TransactionLineGrid`
  - `TransactionLineLookupPopup`
  - `TransactionTotalsFooter`
  - `TransactionActionBar`
  - `TransactionContextSidePanel`
  - `TransactionPrintMenu`
  - `TransactionKeyboardShortcuts`
- Do not duplicate keyboard/grid logic separately for invoices, bills, purchase orders, and receipts.

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

1. Reusable transaction widgets.
2. Invoices / Sales Receipts full accounting screens.
3. Purchase Orders / Bills / Receive Inventory full accounting screens.
4. Payments / Vendor Payments.
5. Sales/Purchase returns and credits polish.
6. Reports polish.
7. POS/cart/mobile fast screens after full screens stabilize.

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
- Next focus: reusable transaction widgets, then Invoices / Sales Receipts full accounting screens.
