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
- [x] Added backend license enforcement skeleton and server status endpoint.
- [x] Added backup/restore API contracts/controller and wired Flutter Backup Settings.
- [x] Added setup API contracts and controller.
- [x] Setup API supports setup status, initialize company, and default account seeding.
- [x] Initialize Company flow creates company settings, ensures system `ADMIN` role with all permissions, creates first admin user, hashes initial admin secret, blocks re-initializing an already initialized company, and seeds default chart of accounts.
- [x] Default accounts seed is idempotent: it creates missing codes and skips existing codes.
- [x] Setup Wizard now calls setup status endpoint, initializes company, and runs default accounts seeding.
- [x] Users & Permissions screen now loads users, roles, and permissions from `SecurityController` APIs.
- [x] Users & Permissions screen supports adding users, adding roles, toggling user active status, replacing user roles, and replacing role permissions for non-system roles.
- [x] Applied first route gates:
  - Backup Settings gated by `LicenseFeature.backupRestore`
  - Payroll route gated by `LicenseFeature.payroll`

### Current Phase B Notes

- The product direction is one codebase with multiple editions controlled by settings and license.
- Offline flow is end-to-end conceptually complete: request code → signed package → public-key verification → local save.
- Online backend exposes `POST /api/licenses/activate` and signs packages using the server-side private key.
- The visible Flutter Activate Online button calls the backend, verifies the returned signed package, and saves it locally.
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
- [x] Polished Chart of Accounts screen:
  - Summary chips for total, active, inactive, debit-normal total, and credit-normal total.
  - Grouped accounts by account type.
  - Responsive search/type/inactive filters.
  - Seed Defaults action from the chart screen.
  - Seed result banner.
  - Better English business wording for commercial UI consistency.
- [x] Polished Account Form screen:
  - Loading state for edit mode.
  - Stronger validation.
  - Commercial layout card.
  - Current balance/status banner in edit mode.
  - Debit-normal / credit-normal account type help.

### Next Recommended Phase C Order

1. Items
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
- Confirmed next Phase C focus: Items, then Customers/Vendors, then sales/purchase transactions.
