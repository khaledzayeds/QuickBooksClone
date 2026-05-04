# LedgerFlow / QuickBooksClone — Work Progress Tracker

> الملف ده هو سجل التقدم العملي للمشروع.  
> أي شغل يتم، أو قرار يتاخد، أو حاجة تخلص، أو حاجة تتأجل، تتسجل هنا عشان نعرف إحنا واقفين فين.

Branch: `local-update`

---

## Current Working Strategy

هنمشي بالترتيب المنطقي التالي:

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

`In Progress`

### Goal

البرنامج يشتغل عند عميل جديد بدون تدخل يدوي، ويدعم نفس الكود لنسخ Solo / Network / Hosted حسب الإعدادات والترخيص.

### Planned Tasks

- [x] Build Settings home screen.
- [x] Build Database/Connection Settings screen.
- [x] Build Company Settings screen.
- [x] Build Setup Wizard skeleton.
- [x] Build Tax Settings screen.
- [ ] Build Backup Settings screen.
- [ ] Build Printer Settings screen.
- [ ] Build Users/Permissions screen.
- [ ] Add backend setup status endpoint if missing.
- [ ] Add initialize company endpoint if missing.
- [ ] Add default accounts seeding flow.
- [ ] Add first admin user flow.

### Already Done

- [x] Added settings models:
  - `RuntimeSettingsModel`
  - `CompanySettingsModel`
- [x] Expanded `CompanySettingsModel` for update payloads matching backend `PUT /api/settings/company`.
- [x] Added settings repository reading existing API endpoints:
  - `GET /api/settings/runtime`
  - `GET /api/settings/company`
  - `PUT /api/settings/company`
- [x] Added settings providers:
  - `runtimeSettingsProvider`
  - `companySettingsProvider`
- [x] Added Settings Home screen:
  - `QuickBooksFlutter/ledgerflow/lib/features/settings/screens/settings_home_screen.dart`
- [x] Wired `/settings` route to `SettingsHomeScreen` instead of `ComingSoonScreen`.
- [x] Added `shared_preferences` dependency for local client settings storage.
- [x] Added connection settings model:
  - `ConnectionSettingsModel`
  - `ConnectionProfileType`: Local / LAN / Hosted / Custom
- [x] Added connection settings repository.
- [x] Added connection settings provider.
- [x] Added Connection Settings screen:
  - `QuickBooksFlutter/ledgerflow/lib/features/settings/screens/connection_settings_screen.dart`
- [x] Added `/settings/connection` route.
- [x] Linked Settings Home Connection tile to `/settings/connection`.
- [x] Added company settings form provider.
- [x] Added Company Settings screen:
  - `QuickBooksFlutter/ledgerflow/lib/features/settings/screens/company_settings_screen.dart`
- [x] Added `/settings/company` route.
- [x] Linked Settings Home Company Profile tile to `/settings/company`.
- [x] Added Tax Settings screen:
  - `QuickBooksFlutter/ledgerflow/lib/features/settings/screens/tax_settings_screen.dart`
- [x] Added `/settings/tax` route.
- [x] Linked Settings Home Tax Settings tile to `/settings/tax`.
- [x] Linked Setup Wizard Tax Defaults step to `/settings/tax`.
- [x] Added Setup Wizard skeleton screen:
  - `QuickBooksFlutter/ledgerflow/lib/features/settings/screens/setup_wizard_screen.dart`
- [x] Added `/settings/setup-wizard` route.
- [x] Linked Settings Home Setup Wizard tile to `/settings/setup-wizard`.

### Current Phase B Notes

- The product direction is one codebase with multiple editions controlled by settings and license.
- Solo: Local API + SQLite.
- Network: LAN API + SQL Server.
- Hosted: Online API + hosted database.
- Connection Settings now supports choosing Local / LAN / Hosted / Custom and testing `/api/settings/runtime`.
- Company Settings now supports loading and saving company profile, contact, address, fiscal year, and basic tax defaults through the existing backend.
- Tax Settings now has a dedicated screen using the same company settings endpoint for tax behavior and rates.
- Setup Wizard skeleton now links to ready steps: Connection, Company, Tax, Chart of Accounts, Finish.
- Coming next: Backup / Printer settings, then backend setup status/initialize endpoints if missing.

---

## Phase C — Core MVP Polish

### Status

`Not Started`

### Goal

تحويل الموديولات الأساسية إلى نسخة قابلة للبيع.

### Modules

- [ ] Customers
- [ ] Vendors
- [ ] Items
- [ ] Chart of Accounts
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

---

## Phase D — Printing + Reports + Backup

### Status

`Not Started`

---

## Phase E — Licensing + Installer

### Status

`Not Started`

---

## Phase F — Banking / Inventory Pro / Payroll

### Status

`Not Started`

---

## Latest Progress Log

### 2026-05-04

- Added roadmap, progress tracker, and local verification checklist.
- Wired missing transaction routes and key navigation areas.
- Added shared `ComingSoonScreen`.
- Started Phase B.
- Added Settings Home, Connection Settings, Company Settings, Tax Settings, and Setup Wizard skeleton.
- Wired `/settings`, `/settings/connection`, `/settings/company`, `/settings/tax`, and `/settings/setup-wizard`.
- Confirmed product direction: one app, editions controlled by Settings + License.
- Next focus: Backup / Printer settings, then setup backend status/initialize endpoints.
