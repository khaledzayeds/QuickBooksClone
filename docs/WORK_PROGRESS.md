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
- [x] Add Ed25519 public-key license signature verification.
- [x] Add Ed25519 license admin signing tools.
- [x] Add online activation backend endpoint.
- [x] Add Flutter online activation repository/provider method.
- [x] Wire License Settings Activate Online button to provider.
- [ ] Add backend users/roles/permissions endpoints.
- [ ] Add backend backup/restore action endpoints.
- [ ] Add backend setup status endpoint if missing.
- [ ] Add initialize company endpoint if missing.
- [ ] Add default accounts seeding flow.
- [ ] Add first admin user flow.
- [ ] Add backend/API license enforcement.

### Already Done

- [x] Added settings models/providers/screens for runtime, company, connection, tax, backup, printing, users/permissions, setup wizard, and license.
- [x] Added `shared_preferences` dependency for local client settings storage.
- [x] Added `crypto` dependency for license fingerprint hashing.
- [x] Added `cryptography` dependency for Ed25519 public-key verification in Flutter.
- [x] Added `DeviceFingerprintService`:
  - Creates a stable installation id on first run.
  - Stores it locally.
  - Generates SHA-256 device fingerprint from installation id + app salt.
  - Supports rotate-for-testing method for later QA tooling.
- [x] License Settings now displays Installation ID, Device Fingerprint, Generated At, and Use This Device.
- [x] Added `OfflineActivationService` and Offline Activation Request UI.
- [x] Added Ed25519 public-key verification flow in Flutter.
- [x] Added license admin tools for Ed25519 keypair/package signing.
- [x] Added backend licensing contracts:
  - `QuickBooksClone.Core/Licensing/LicenseActivationModels.cs`
- [x] Added backend Ed25519 signing service:
  - `QuickBooksClone.Infrastructure/Licensing/Ed25519LicensePackageSigningService.cs`
- [x] Added backend configuration activation service:
  - `QuickBooksClone.Infrastructure/Licensing/ConfigurationLicenseActivationService.cs`
- [x] Added backend API endpoint:
  - `POST /api/licenses/activate`
  - `QuickBooksClone.Api/Controllers/LicensesController.cs`
- [x] Added API contracts:
  - `QuickBooksClone.Api/Contracts/Licensing/LicenseActivationContracts.cs`
- [x] Registered licensing services in `QuickBooksClone.Api/Program.cs`.
- [x] Added sample licensing config in `QuickBooksClone.Api/appsettings.json` without a real private key.
- [x] Added `BouncyCastle.Cryptography` for backend Ed25519 signing.
- [x] Added Flutter online activation repository/provider methods.
- [x] Wired visible Activate Online button in `LicenseSettingsScreen`.

### Current Phase B Notes

- The product direction is one codebase with multiple editions controlled by settings and license.
- License skeleton supports Trial / Solo / Network / Hosted, limits, feature flags, license key, device id, expiry, and local save.
- Offline flow is end-to-end conceptually complete: request code → signed package → public-key verification → local save.
- Online backend now exposes `POST /api/licenses/activate` and signs packages using the server-side private key.
- The visible Flutter Activate Online button now calls the backend, verifies the returned signed package, and saves it locally.
- The server private key must be supplied through `Licensing:PrivateKey` or `LEDGERFLOW_LICENSE_PRIVATE_KEY`; do not commit a real private key.
- Backend/API license enforcement is still pending; current gates are mainly Flutter-side.
- A real production public key must be generated and pasted into `LicensePublicKeyConfig` before using the flow commercially.
- Backup Settings currently reads runtime database status from `GET /api/settings/runtime` and exposes disabled backup/restore actions until backend action endpoints are added.

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
- [x] License activation design document.

### Pending

- [ ] Backend/API license enforcement.
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
- Wired missing transaction routes and key navigation areas.
- Added shared `ComingSoonScreen`.
- Started Phase B.
- Added Settings Home, Connection Settings, Company Settings, Tax Settings, Backup Settings, Printing Settings, Users & Permissions skeleton, License Settings skeleton, and Setup Wizard skeleton.
- Added Setup Wizard Start Mode with Create New Company / Restore Backup / Connect Existing / Demo Company options.
- Added LicenseFeature, license helper methods, reusable LicenseGate, and initial route gates for Backup/Restore and Payroll.
- Added gates for Setup Wizard Start Mode options and Connection Settings profiles based on the current license edition.
- Added DeviceFingerprintService and surfaced Installation ID / Device Fingerprint in License Settings.
- Added Offline Activation Request service and UI so the customer can generate a request code from the target device.
- Added Ed25519 public-key verification in Flutter and Ed25519 signing tools for offline license packages.
- Added online activation backend endpoint, Flutter repository/provider method, and visible Activate Online action.
- Added `docs/LICENSE_ACTIVATION_DESIGN.md` documenting signed license payloads, serial generation, device fingerprint, online activation, offline activation, expiry/renewal, and owner/admin workflows.
- Wired `/settings`, `/settings/connection`, `/settings/company`, `/settings/tax`, `/settings/backup`, `/settings/printing`, `/settings/users-permissions`, `/settings/license`, and `/settings/setup-wizard`.
- Confirmed product direction: one app, editions controlled by Settings + License.
- Next focus: backend/API license enforcement, backup/setup endpoints, or installer integration.
