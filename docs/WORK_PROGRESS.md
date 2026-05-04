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
- [x] Add backend/API license enforcement skeleton.
- [x] Add backend backup/restore action endpoints.
- [x] Wire Flutter Backup Settings to backup/restore API.
- [ ] Add backend users/roles/permissions endpoints.
- [ ] Add backend setup status endpoint if missing.
- [ ] Add initialize company endpoint if missing.
- [ ] Add default accounts seeding flow.
- [ ] Add first admin user flow.

### Already Done

- [x] Added settings models/providers/screens for runtime, company, connection, tax, backup, printing, users/permissions, setup wizard, and license.
- [x] Added `shared_preferences` dependency for local client settings storage.
- [x] Added `crypto` dependency for license fingerprint hashing.
- [x] Added `cryptography` dependency for Ed25519 public-key verification in Flutter.
- [x] Added `DeviceFingerprintService` and License Settings device fingerprint display.
- [x] Added `OfflineActivationService` and Offline Activation Request UI.
- [x] Added Ed25519 public-key verification flow in Flutter.
- [x] Added license admin tools for Ed25519 keypair/package signing.
- [x] Added backend licensing contracts, Ed25519 signing service, configuration activation service, and `POST /api/licenses/activate`.
- [x] Added Flutter online activation repository/provider methods and wired visible Activate Online button.
- [x] Added backend license enforcement skeleton:
  - `QuickBooksClone.Api/Security/RequireLicenseFeatureAttribute.cs`
  - `QuickBooksClone.Core/Licensing/ILicenseFeatureAccessService.cs`
  - `QuickBooksClone.Infrastructure/Licensing/ConfigurationLicenseFeatureAccessService.cs`
  - `QuickBooksClone.Api/Middleware/LicenseFeatureMiddleware.cs`
  - Registered `ILicenseFeatureAccessService` and `LicenseFeatureMiddleware` in `Program.cs`.
  - Added `GET /api/licenses/status`.
  - Added sample `Licensing:CurrentLicense` config in `appsettings.json`.
- [x] Added backup/restore API contracts and controller:
  - `QuickBooksClone.Api/Contracts/Backups/BackupContracts.cs`
  - `QuickBooksClone.Api/Controllers/BackupsController.cs`
- [x] Backup API is protected by `[RequireLicenseFeature(LicenseFeatureNames.BackupRestore)]`.
- [x] Backup API supports:
  - `GET /api/backups`
  - `GET /api/backups/settings`
  - `PUT /api/backups/settings`
  - `POST /api/backups`
  - `POST /api/backups/import`
  - `POST /api/backups/restore`
  - `GET /api/backups/restore-audits`
- [x] Added Flutter backup models/repository/provider:
  - `backup_models.dart`
  - `backup_repository.dart`
  - `backup_provider.dart`
- [x] Backup Settings screen now lists backups, creates manual backup, restores backup with confirmation/safety backup option, shows policy, and shows restore audit log.
- [x] Applied first route gates:
  - Backup Settings gated by `LicenseFeature.backupRestore`
  - Payroll route gated by `LicenseFeature.payroll`

### Current Phase B Notes

- The product direction is one codebase with multiple editions controlled by settings and license.
- Offline flow is end-to-end conceptually complete: request code → signed package → public-key verification → local save.
- Online backend exposes `POST /api/licenses/activate` and signs packages using the server-side private key.
- The visible Flutter Activate Online button calls the backend, verifies the returned signed package, and saves it locally.
- Backend license enforcement exists as a reusable skeleton using `[RequireLicenseFeature("featureName")]` and `Licensing:CurrentLicense`.
- Backup/Restore is now the first paid feature protected on both Flutter and API layers.
- The server private key must be supplied through `Licensing:PrivateKey` or `LEDGERFLOW_LICENSE_PRIVATE_KEY`; do not commit a real private key.
- A real production public key must be generated and pasted into `LicensePublicKeyConfig` before using the flow commercially.
- Import Backup endpoint exists but Flutter import file picker is not wired yet.

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
- Added backend/API license enforcement skeleton and server license status endpoint.
- Added backup/restore API endpoints protected by BackupRestore license feature.
- Wired Flutter Backup Settings to list/create/restore backups and show restore audit log.
- Added `docs/LICENSE_ACTIVATION_DESIGN.md` documenting signed license payloads, serial generation, device fingerprint, online activation, offline activation, expiry/renewal, and owner/admin workflows.
- Wired `/settings`, `/settings/connection`, `/settings/company`, `/settings/tax`, `/settings/backup`, `/settings/printing`, `/settings/users-permissions`, `/settings/license`, and `/settings/setup-wizard`.
- Confirmed product direction: one app, editions controlled by Settings + License.
- Next focus: setup status/init company endpoints, users/permissions backend, installer integration, or Core MVP polish.
