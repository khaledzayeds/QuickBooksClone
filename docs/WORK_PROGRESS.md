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

`Reusable foundation started`

### Product Decision

Start with full accounting transaction screens first, not cart-only screens. The first sales and purchase screens should be QuickBooks-style full screens with all important accounting controls visible: customer/vendor, document number, status, dates, terms, line grid, tax, discounts, totals, side context panel, preview, print, save, and post.

Fast POS/cart/mobile screens are still planned, but they should be built later as separate modes using the same backend and reusable transaction components. They must not replace the full accounting screen.

### Reusable Transaction Widgets Started

- [x] `transaction_models.dart`
  - Shared transaction kind/status/party/print enums.
  - Shared line, totals, context metric, and activity UI models.
- [x] `transaction_header_panel.dart`
  - Full transaction header with document kind, status, number, date, due date, terms, and reference fields.
- [x] `transaction_party_selector.dart`
  - Reusable customer/vendor/account selector with balance/credit chips.
- [x] `transaction_line_grid.dart`
  - Scanner-friendly item/barcode/SKU entry.
  - Wide transaction line grid with item, description, qty, unit, rate, discount, tax, amount, warnings, and row actions.
  - Shows shortcut hint text.
- [x] `transaction_totals_footer.dart`
  - Reusable subtotal/discount/tax/shipping/total/paid/balance due footer.
- [x] `transaction_print_menu.dart`
  - Preview A4, Print A4, Print Thermal, Email/Share menu skeleton.
- [x] `transaction_action_bar.dart`
  - Save Draft, Save, Post, Print, Clear, and Void actions with status-aware disabling.
- [x] `transaction_context_side_panel.dart`
  - Collapsible right panel with party snapshot metrics, recent activity, warnings, and notes.
- [x] `transaction_keyboard_shortcuts.dart`
  - Shortcut wrapper for Ctrl+Enter, F4, F5, F7, F8, F9, F10, Ctrl+S, Ctrl+P, Ctrl+D, Ctrl+L, and Esc.

### Still Needed Before Invoice Screen Is Final

- [ ] Wire shortcut callbacks into real focus nodes/cell navigation.
- [ ] Build lightweight item lookup popup under active grid cell.
- [ ] Connect real customer/item repositories to invoice screen.
- [ ] Add invoice/sales receipt form state provider.
- [ ] Add print preview service integration.

### Implementation Direction

- Build reusable transaction widgets before polishing every screen separately.
- Do not duplicate keyboard/grid logic separately for invoices, bills, purchase orders, and receipts.
- First real consumer should be full accounting Invoice / Sales Receipt screen.

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

1. Wire reusable transaction widgets into Invoices / Sales Receipts full accounting screens.
2. Purchase Orders / Bills / Receive Inventory full accounting screens.
3. Payments / Vendor Payments.
4. Sales/Purchase returns and credits polish.
5. Reports polish.
6. POS/cart/mobile fast screens after full screens stabilize.

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
- Next focus: wire reusable transaction widgets into Invoices / Sales Receipts full accounting screens.
