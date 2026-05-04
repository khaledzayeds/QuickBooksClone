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

### Goal

البرنامج يشتغل عند عميل جديد بدون تدخل يدوي، ويدعم نفس الكود لنسخ Solo / Network / Hosted حسب الإعدادات والترخيص.

### Planned Tasks

- [x] Build Settings home screen.
- [x] Build Database/Connection Settings screen.
- [x] Build Company Settings screen.
- [x] Build Setup Wizard skeleton.
- [x] Build Setup Wizard Start Mode step.
- [x] Build Tax Settings screen.
- [x] Build Backup Settings screen.
- [x] Build Printer Settings screen.
- [x] Build Users/Permissions screen.
- [x] Add license skeleton screen/model/provider.
- [x] Add license gate helpers.
- [x] Add license activation design document.
- [x] Gate Setup Wizard Start Mode options by license.
- [x] Gate Connection Settings profiles by license.
- [x] Add device fingerprint skeleton.
- [x] Add signed/offline license package skeleton.
- [x] Add offline activation request code flow.
- [x] Add Ed25519 public-key license signature verification.
- [x] Add Ed25519 license admin signing tools.
- [x] Add online activation backend endpoint.
- [x] Add Flutter online activation repository/provider method.
- [x] Wire License Settings Activate Online button to provider.
- [x] Add backend/API license enforcement skeleton.
- [x] Add backend backup/restore action endpoints.
- [x] Wire Flutter Backup Settings to backup/restore API.
- [x] Add setup status endpoint.
- [x] Add initialize company endpoint.
- [x] Add first admin user flow.
- [x] Wire Flutter Setup Wizard to setup status/init endpoints.
- [x] Add default accounts seeding flow.
- [x] Wire Users & Permissions screen to security API.

### Current Phase B Notes

- The product direction is one codebase with multiple editions controlled by settings and license.
- Backup/Restore is now the first paid feature protected on both Flutter and API layers.
- Users & Permissions is now wired to backend security APIs, but password reset/change UI, audit log, device activation limits, and license user-limit enforcement are still future polish.
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

## Phase C — Core MVP Polish

### Status

`Started`

### Goal

تحويل الموديولات الأساسية إلى نسخة قابلة للبيع.

### Modules

- [ ] Customers
- [ ] Vendors
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

### Items Polish Plan

#### Core Item Types — current implementation target

- [x] Inventory Part
  - Tracks quantity on hand.
  - Requires Income, Inventory Asset, and COGS accounts.
  - Opening quantity posts opening inventory value when configured.
- [x] Non-inventory Part
  - Does not track stock.
  - Can be sold, purchased, or both.
  - Requires Income and/or Expense account.
- [x] Service
  - Does not track stock.
  - Can be sold, purchased, or both.
  - Requires Income and/or Expense account.
- [x] Bundle / Group skeleton
  - Should not post directly to income.
  - Component-driven posting is future work.

#### QuickBooks-style advanced item types — planned after core transaction stability

- [ ] Other Charge
- [ ] Subtotal
- [ ] Discount
- [ ] Payment item
- [ ] Sales Tax Item
- [ ] Sales Tax Group
- [ ] Inventory Assembly / Build Assemblies
- [ ] Fixed Asset Item

#### Items UX / Productivity backlog

- [ ] Item List polish with grouped view, type tabs/cards, stock alerts, and account badges.
- [ ] Item Details polish with posting accounts, stock status, sales/purchase summary, and related transactions placeholders.
- [ ] Add/Edit Multiple Items grid.
- [ ] Import Items from Excel/CSV.
- [ ] Export Items to Excel/CSV.
- [ ] Download sample import template.
- [ ] Change Item Prices screen/action.
- [ ] Inventory Center style screen after list/details are stable.

### Items Work Done So Far

- [x] Fixed Flutter items datasource item type query bug.
- [x] Updated item active toggle API to return `ItemDto` instead of `204 NoContent`.
- [x] Added backend QuickBooks-style validation for Inventory / Non-inventory / Service / Bundle account links.
- [x] Added item type account selectors in Flutter Item Form.
- [x] Added default account selection helpers in Item Form.
- [x] Added opening quantity warning and validation.

### Next Recommended Phase C Order

1. Finish Items list/details polish.
2. Customers
3. Vendors
4. Invoices / Sales Receipts
5. Purchase Orders / Bills / Receive Inventory
6. Payments / Vendor Payments
7. Reports polish

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
- Started Phase C Core MVP Polish.
- Polished Chart of Accounts backend/frontend flow and fixed account datasource/toggle mismatches.
- Started Items polish with QuickBooks-style type/account behavior.
- Added Items plan for core types, advanced QuickBooks-style types, Add/Edit Multiple, Excel import/export, and Inventory Center future screen.
