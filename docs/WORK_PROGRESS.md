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
- [x] Add license skeleton screen/model/provider.
- [x] Add license gate helpers.
- [x] Add license activation design document.
- [x] Gate Setup Wizard Start Mode options by license.
- [x] Gate Connection Settings profiles by license.
- [x] Add device fingerprint skeleton.
- [x] Add signed/offline license package skeleton.
- [x] Add offline activation request code flow.
- [ ] Add backend users/roles/permissions endpoints.
- [ ] Add backend backup/restore action endpoints.
- [ ] Add backend setup status endpoint if missing.
- [ ] Add initialize company endpoint if missing.
- [ ] Add default accounts seeding flow.
- [ ] Add first admin user flow.
- [ ] Add real public-key license signature verification.
- [ ] Add license activation server/manual offline validation.

### Already Done

- [x] Added settings models/providers/screens for runtime, company, connection, tax, backup, printing, users/permissions, setup wizard, and license.
- [x] Added `shared_preferences` dependency for local client settings storage.
- [x] Added `crypto` dependency for license fingerprint hashing.
- [x] Added `DeviceFingerprintService`:
  - Creates a stable installation id on first run.
  - Stores it locally.
  - Generates SHA-256 device fingerprint from installation id + app salt.
  - Supports rotate-for-testing method for later QA tooling.
- [x] License Settings now displays:
  - Installation ID
  - Device Fingerprint
  - Generated At
  - Use This Device button to copy fingerprint into Activated Device ID field.
- [x] Added `OfflineActivationService`:
  - Generates `LFREQ.<base64url(payload)>` request codes.
  - Includes serial, customer name, requested edition, device fingerprint, installation id, app name, and creation timestamp.
  - Includes decode helper for future admin tooling.
- [x] License Settings now includes Offline Activation Request card:
  - Generate Request Code
  - Request Code display
  - Created At
  - Payload Preview
- [x] Added `LicensePackageVerifier` skeleton:
  - Accepts `base64url(payloadJson).base64url(signature)`.
  - Decodes payload.
  - Checks optional `deviceId` against current fingerprint.
  - Maps payload to `LicenseSettingsModel`.
  - Uses placeholder non-empty signature check until production public-key verification is added.
- [x] Added repository/provider apply package flow:
  - `LicenseSettingsRepository.applyPackage(...)`
  - `LicenseSettingsNotifier.applyPackage(...)`
- [x] License Settings now includes a Signed / Offline License Package input card with Apply Package button.
- [x] Added Setup Wizard Start Mode step:
  - Create New Company
  - Restore Existing Backup
  - Connect To Existing Company
  - Open Demo Company
- [x] Setup Wizard Start Mode now checks the current license:
  - Create New Company requires at least one allowed connection mode.
  - Restore Existing Backup requires `LicenseFeature.backupRestore`.
  - Connect To Existing Company requires LAN or Hosted feature.
  - Demo Company checks `LicenseFeature.demoCompany` and remains planned until demo seed is added.
- [x] Connection Settings profiles now check the current license:
  - Local requires `LicenseFeature.localMode`.
  - LAN requires `LicenseFeature.lanMode`.
  - Hosted requires `LicenseFeature.hostedMode`.
  - Custom requires at least one connection mode.
- [x] Added license settings model/repository/provider:
  - `LicenseSettingsModel`
  - `LicenseSettingsRepository`
  - `licenseSettingsProvider`
- [x] Added License Settings screen:
  - `QuickBooksFlutter/ledgerflow/lib/features/settings/screens/license_settings_screen.dart`
- [x] Added `/settings/license` route and linked Settings Home License tile.
- [x] Added license helper logic:
  - `LicenseFeature`
  - `LicenseSettingsModel.canUseApp`
  - `LicenseSettingsModel.allows(feature)`
  - `LicenseSettingsModel.denialReason(feature)`
- [x] Added reusable license gate widget:
  - `QuickBooksFlutter/ledgerflow/lib/features/settings/widgets/license_gate.dart`
- [x] Applied first route gates:
  - Backup Settings gated by `LicenseFeature.backupRestore`
  - Payroll route gated by `LicenseFeature.payroll`
- [x] Added license activation design document:
  - `docs/LICENSE_ACTIVATION_DESIGN.md`

### Current Phase B Notes

- The product direction is one codebase with multiple editions controlled by settings and license.
- License skeleton supports Trial / Solo / Network / Hosted, limits, feature flags, license key, device id, expiry, and local save.
- Device fingerprint skeleton is local-installation based for now. Production can later add OS/device attributes carefully without storing raw sensitive values.
- License package flow is wired end-to-end as a development skeleton. It does not yet perform real cryptographic public-key verification.
- Offline request code flow is now wired in the UI so a customer can generate a request code from the target device.
- License Gate is now available for screens/features and shows a clear License Required screen when blocked.
- Production activation still needs real signed payload verification, online/offline activation admin tooling, renewal/expiry rules, and backend verification.
- Solo: Local API + SQLite.
- Network: LAN API + SQL Server.
- Hosted: Online API + hosted database.
- Setup Wizard starts with Start Mode instead of forcing First Admin immediately.
- Restore path should restore a company backup first, then login with restored users. Recovery Admin should be an exceptional flow only.
- Connect Existing path should connect to LAN/Hosted API and login with server-side users. No local first admin creation.
- Backup Settings currently reads runtime database status from `GET /api/settings/runtime` and exposes disabled backup/restore actions until backend action endpoints are added.
- Printing Settings stores local client preferences for A4 and thermal printing, including print mode, A4 template style, 58/80mm thermal width, logo path, QR, tax summary, customer balance, SKU display, Arabic fonts, preview behavior, and footer messages.
- Coming next: real public-key signature verification, admin tool for generating packages, online activation endpoint, or backend backup/users/setup endpoints.

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

`Started as Skeleton`

### Done

- [x] License Settings skeleton.
- [x] License model/repository/provider.
- [x] License gate helpers.
- [x] Initial gated routes.
- [x] Start Mode gates.
- [x] Connection profile gates.
- [x] Device fingerprint skeleton.
- [x] Signed/offline license package skeleton.
- [x] Offline activation request code flow.
- [x] License activation design document.

### Pending

- [ ] Real public-key signed license payload verification.
- [ ] Online activation endpoint.
- [ ] Admin tool for generating serials and signed licenses.
- [ ] Installer integration.

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
- Added Settings Home, Connection Settings, Company Settings, Tax Settings, Backup Settings, Printing Settings, Users & Permissions skeleton, License Settings skeleton, and Setup Wizard skeleton.
- Added Setup Wizard Start Mode with Create New Company / Restore Backup / Connect Existing / Demo Company options.
- Added LicenseFeature, license helper methods, reusable LicenseGate, and initial route gates for Backup/Restore and Payroll.
- Added gates for Setup Wizard Start Mode options and Connection Settings profiles based on the current license edition.
- Added DeviceFingerprintService and surfaced Installation ID / Device Fingerprint in License Settings.
- Added LicensePackageVerifier skeleton and Signed / Offline License Package UI in License Settings.
- Added Offline Activation Request service and UI so the customer can generate a request code from the target device.
- Added `docs/LICENSE_ACTIVATION_DESIGN.md` documenting signed license payloads, serial generation, device fingerprint, online activation, offline activation, expiry/renewal, and owner/admin workflows.
- Wired `/settings`, `/settings/connection`, `/settings/company`, `/settings/tax`, `/settings/backup`, `/settings/printing`, `/settings/users-permissions`, `/settings/license`, and `/settings/setup-wizard`.
- Confirmed product direction: one app, editions controlled by Settings + License.
- Next focus: real public-key signature verification, admin tool for generating packages, online activation endpoint, or backend backup/users/setup endpoints.
