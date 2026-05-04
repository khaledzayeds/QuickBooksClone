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

---

## Phase A — Stability / Build Lock

### Status

`In Progress`

### Goal

تثبيت المشروع قبل إضافة موديولات كبيرة.

### Tasks

- [ ] Run `dotnet build` locally and capture output.
- [ ] Run `flutter analyze` locally and capture output.
- [ ] Fix backend compile errors.
- [ ] Fix Flutter analyzer blocking errors.
- [ ] Review and remove old temporary files.
- [x] Replace known hardcoded transaction routes with `AppRoutes` in return/credit screens.
- [x] Add shared `ComingSoonScreen` instead of inline placeholder builder.
- [x] Review main route consistency for core list screens.
- [x] Create local verification checklist.
- [ ] Confirm all main routes open.
- [ ] Confirm auth redirect/login flow works.
- [ ] Confirm API starts and migrations apply.

### Known Findings / Gaps

- `purchase_bill_list_screen.dart` has a TODO inside `onTap` and no purchase bill details route yet. This belongs to Phase C Core MVP Polish.
- GitHub code search did not return obvious hits for `*_fixed.dart`, `router_fixed.dart`, `router_full_fixed.dart`, or old `Errors.txt`, but local repository scan is still recommended after pulling.

---

## Phase B — Settings + Setup Wizard + Connection

### Status

`Mostly Complete / Polish Remaining`

### Current Phase B Notes

- The product direction is one codebase with multiple editions controlled by settings and license.
- Backup/Restore is now the first paid feature protected on both Flutter and API layers.
- Users & Permissions is wired to backend security APIs, but password reset/change UI, audit log, device activation limits, and license user-limit enforcement are still future polish.
- Import Backup endpoint exists but Flutter import file picker is not wired yet.

---

## Post Phase B Polish Backlog

### Status

`Scheduled / Not Blocking Core MVP Start`

### Planned Order

1. **Import Backup File Picker** — during Phase D backup polish.
2. **Password Reset / Change UI** — after auth/login flow is verified.
3. **Audit Log Display** — after transaction/posting screens are stable.
4. **License User-Limit Enforcement** — before selling licensed builds.
5. **Device Activation Limits** — before selling Network/Hosted or multi-device editions.

---

## Localization Cleanup Backlog

### Status

`Scheduled / After UI Stabilization`

### Policy

- Continue fast commercial UI polish now, even if some visible strings are temporarily hardcoded.
- After each module becomes functionally stable, move visible user-facing strings into the existing localization files.
- Arabic/English switching from settings remains a product requirement.
- Avoid mixing Arabic and English inside the same polished screen unless intentionally localized.

### Screens needing later localization pass

- [ ] Settings / Setup Wizard screens.
- [ ] Backup Settings screen.
- [ ] Users & Permissions screen.
- [ ] Chart of Accounts and Account Form screens.
- [ ] Items screens: List, Form, Details, Card widgets.
- [ ] Customers screens: List, Form, Details, Card widgets.
- [ ] Vendors screens: List, Form, Details, Card widgets.
- [ ] Future transaction screens.

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

### Chart of Accounts Polish Done

- [x] Fixed Flutter account type query filtering bug in `AccountsRemoteDatasource`.
- [x] Updated backend active toggle endpoint to return the updated `AccountDto` instead of `204 NoContent`, matching Flutter expectations.
- [x] Polished Chart of Accounts screen and Account Form screen.

### Items Work Done So Far

- [x] Fixed Flutter items datasource item type query bug.
- [x] Updated item active toggle API to return `ItemDto` instead of `204 NoContent`.
- [x] Added backend QuickBooks-style validation for Inventory / Non-inventory / Service / Bundle account links.
- [x] Added item type account selectors in Flutter Item Form.
- [x] Added default account selection helpers in Item Form.
- [x] Added opening quantity warning and validation.
- [x] Added commercial item type labels and helpers for required posting accounts, gross margin, and inventory value.
- [x] Polished `ItemCard` with type/SKU/status badges, sales/cost/margin/stock/value metrics, and missing-account warnings.
- [x] Polished `ItemListScreen` into an Inventory Center style screen.
- [x] Polished `ItemDetailsScreen` with metrics, posting accounts, quick actions, and future activity placeholder.

### Customers Polish Done

- [x] Updated backend customer active toggle endpoint to return the updated `CustomerDto` instead of `204 NoContent`, matching Flutter expectations.
- [x] Hardened `CustomerModel` parsing and added helpers for contact info, net receivable, and balance flags.
- [x] Polished `CustomerCard` with status/contact chips, open balance, credit balance, net receivable, and warning indicator.
- [x] Polished `CustomerListScreen` into a Customer Center style screen.
- [x] Polished `CustomerFormScreen` with edit loading, commercial layout, contact validation, opening balance warning, and balance/status banner.
- [x] Polished `CustomerDetailsScreen` with header, balance metrics, contact section, quick actions, and future activity placeholder.

### Customers Productivity Backlog

- [ ] Import Customers from Excel/CSV.
- [ ] Export Customers to Excel/CSV.
- [ ] Download customer import template.
- [ ] Customer Statement Batch.
- [ ] Customer activity center after transaction screens are stable.

### Vendors Polish Done

- [x] Updated backend vendor active toggle endpoint to return the updated `VendorDto` instead of `204 NoContent`, matching Flutter expectations.
- [x] Hardened `VendorModel` parsing and added helpers for contact info, net payable, and payable flags.
- [x] Polished `VendorCard` with status/contact chips, open payable, vendor credits, net payable, and warning indicator.
- [x] Polished `VendorListScreen` into a Vendor Center style screen:
  - Summary chips for vendors, active, inactive, open payable, vendor credits, missing contact info, and payable vendors.
  - Search and inactive filter.
  - Grouped sections for open payables, vendor credits available, and no open payable.
  - Actions menu for import/export/template/statements as scheduled productivity backlog actions.
- [x] Polished `VendorFormScreen`:
  - Loading state for edit mode.
  - Commercial layout card.
  - Contact validation.
  - Opening payable balance warning and explanation.
  - Payable/status banner in edit mode.
- [x] Polished `VendorDetailsScreen`:
  - Header with status/currency/payable badges.
  - Payable metrics.
  - Contact information section.
  - Quick actions for purchase order, purchase bill, vendor payment, and edit.
  - Related activity placeholder for future purchase transaction history.

### Vendors Productivity Backlog

- [ ] Import Vendors from Excel/CSV.
- [ ] Export Vendors to Excel/CSV.
- [ ] Download vendor import template.
- [ ] Vendor Statement Batch.
- [ ] Vendor activity center after transaction screens are stable.

### Next Recommended Phase C Order

1. Invoices / Sales Receipts
2. Purchase Orders / Bills / Receive Inventory
3. Payments / Vendor Payments
4. Sales/Purchase returns and credits polish
5. Reports polish

---

## Phase D — Printing + Reports + Backup

### Status

`Started`

### Done

- [x] Backend backup/restore service existed in Infrastructure.
- [x] API endpoints added and license-protected.
- [x] Flutter Backup Settings wired for list/create/restore/audit.

### Pending

- [ ] Flutter import backup file picker.
- [ ] Download/export backup file endpoint if needed.
- [ ] Scheduled automatic backups/background task.

---

## Phase E — Licensing + Installer

### Status

`Started as Functional Skeleton`

### Done

- [x] License Settings skeleton.
- [x] License model/repository/provider.
- [x] License gate helpers.
- [x] Initial gated routes.
- [x] Start Mode gates.
- [x] Connection profile gates.
- [x] Device fingerprint skeleton.
- [x] Signed/offline license package flow.
- [x] Offline activation request code flow.
- [x] Ed25519 public-key package verification in Flutter.
- [x] Ed25519 admin keypair/package signing tools.
- [x] Online activation backend endpoint.
- [x] Visible Flutter online activation action.
- [x] Backend/API license enforcement skeleton.
- [x] License activation design document.

### Pending

- [ ] Apply backend license attributes to future payroll/advanced inventory APIs.
- [ ] Production admin panel for generating serials and signed licenses.
- [ ] Installer integration.

---

## Phase F — Banking / Inventory Pro / Payroll

### Status

`Not Started`

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
- Next focus: sales transaction screens, starting with Invoices / Sales Receipts.
