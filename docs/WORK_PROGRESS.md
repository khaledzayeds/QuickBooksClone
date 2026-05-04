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

`UI Skeleton Mostly Complete / Backend Wiring Needed`

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
- [ ] Add backend users/roles/permissions endpoints.
- [ ] Add backend backup/restore action endpoints.
- [ ] Add backend setup status endpoint if missing.
- [ ] Add initialize company endpoint if missing.
- [ ] Add default accounts seeding flow.
- [ ] Add first admin user flow.
- [ ] Add license skeleton screen/model/provider.

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
- [x] Added connection settings repository/provider/screen.
- [x] Added `/settings/connection` route and linked Settings Home.
- [x] Added company settings form provider and Company Settings screen.
- [x] Added `/settings/company` route and linked Settings Home.
- [x] Added Tax Settings screen.
- [x] Added `/settings/tax` route.
- [x] Linked Settings Home and Setup Wizard to Tax Settings.
- [x] Added Backup Settings screen:
  - `QuickBooksFlutter/ledgerflow/lib/features/settings/screens/backup_settings_screen.dart`
- [x] Added `/settings/backup` route.
- [x] Linked Settings Home Database & Backup tile to `/settings/backup`.
- [x] Linked Setup Wizard Backup step to `/settings/backup` as Partial.
- [x] Added printing settings model/repository/provider:
  - `PrintingSettingsModel`
  - `PrintingSettingsRepository`
  - `printingSettingsProvider`
- [x] Added Printing Settings screen:
  - `QuickBooksFlutter/ledgerflow/lib/features/settings/screens/printing_settings_screen.dart`
- [x] Added `/settings/printing` route.
- [x] Linked Settings Home Printing tile to `/settings/printing`.
- [x] Linked Setup Wizard Printing step to `/settings/printing` as Ready.
- [x] Added Users & Permissions skeleton screen:
  - `QuickBooksFlutter/ledgerflow/lib/features/settings/screens/users_permissions_screen.dart`
- [x] Added `/settings/users-permissions` route.
- [x] Linked Settings Home Users & Permissions tile to `/settings/users-permissions`.
- [x] Linked Setup Wizard Users & Permissions step to `/settings/users-permissions` as Partial.
- [x] Added Setup Wizard skeleton screen:
  - `QuickBooksFlutter/ledgerflow/lib/features/settings/screens/setup_wizard_screen.dart`
- [x] Added Setup Wizard Start Mode step:
  - Create New Company
  - Restore Existing Backup
  - Connect To Existing Company
  - Open Demo Company
- [x] Added `/settings/setup-wizard` route and linked Settings Home.

### Current Phase B Notes

- The product direction is one codebase with multiple editions controlled by settings and license.
- Solo: Local API + SQLite.
- Network: LAN API + SQL Server.
- Hosted: Online API + hosted database.
- Setup Wizard now starts with Start Mode instead of forcing First Admin immediately.
- New Company path should create company profile, first admin, default accounts, tax, printing, and backup policy.
- Restore path should restore a company backup first, then login with restored users. Recovery Admin should be an exceptional flow only.
- Connect Existing path should connect to LAN/Hosted API and login with server-side users. No local first admin creation.
- Demo path is planned for sample data and training/sales presentation.
- Connection Settings supports choosing Local / LAN / Hosted / Custom and testing `/api/settings/runtime`.
- Company Settings supports loading/saving company profile, contact, address, fiscal year, and basic tax defaults through existing backend.
- Tax Settings has a dedicated screen using the same company settings endpoint for tax behavior and rates.
- Backup Settings currently reads runtime database status from `GET /api/settings/runtime` and exposes disabled backup/restore actions until backend action endpoints are added.
- Printing Settings stores local client preferences for A4 and thermal printing, including print mode, A4 template style, 58/80mm thermal width, logo path, QR, tax summary, customer balance, SKU display, Arabic fonts, preview behavior, and footer messages.
- Users & Permissions is a commercial skeleton screen for first admin, default roles, permission groups, users/devices, and required backend endpoints.
- Setup Wizard links to ready/partial steps: Start Mode, Connection, Company, Tax, Chart of Accounts, Users & Permissions, Backup, Printing, Finish.
- Coming next: License skeleton or backend backup/users/setup endpoints.

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
- Added Settings Home, Connection Settings, Company Settings, Tax Settings, Backup Settings, Printing Settings, Users & Permissions skeleton, and Setup Wizard skeleton.
- Added Setup Wizard Start Mode with Create New Company / Restore Backup / Connect Existing / Demo Company options.
- Wired `/settings`, `/settings/connection`, `/settings/company`, `/settings/tax`, `/settings/backup`, `/settings/printing`, `/settings/users-permissions`, and `/settings/setup-wizard`.
- Confirmed product direction: one app, editions controlled by Settings + License.
- Next focus: License skeleton or backend backup/users/setup endpoints.
