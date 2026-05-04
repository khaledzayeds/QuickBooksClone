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

### Already Done

- [x] Created commercial readiness roadmap: `docs/COMMERCIAL_READINESS_ROADMAP.md`.
- [x] Created local verification checklist: `docs/LOCAL_VERIFICATION_CHECKLIST.md`.
- [x] Added missing transaction routes to `QuickBooksFlutter/ledgerflow/lib/app/router.dart`.
- [x] Wired routes for Sales Returns, Customer Credits, Purchase Returns, Vendor Credits.
- [x] Added named placeholders for unfinished modules.
- [x] Added shared coming-soon screen: `QuickBooksFlutter/ledgerflow/lib/core/widgets/coming_soon_screen.dart`.
- [x] Replaced inline router placeholders with shared `ComingSoonScreen`.
- [x] Wired dashboard flowchart navigation.
- [x] Wired top menu navigation.
- [x] Wired sidebar navigation.
- [x] Replaced hardcoded list/form navigation routes in returns/credits screens.
- [x] Replaced hardcoded details routes in invoices and sales receipts list screens.
- [x] Reviewed route consistency in core list screens.
- [x] Created this progress tracker.

### Known Findings / Gaps

- `purchase_bill_list_screen.dart` has a TODO inside `onTap` and no purchase bill details route yet. This belongs to Phase C Core MVP Polish.
- GitHub code search did not return obvious hits for `*_fixed.dart`, `router_fixed.dart`, `router_full_fixed.dart`, or old `Errors.txt`, but local repository scan is still recommended after pulling.

### Current Blockers

- Local build/analyze output is still needed from the developer machine because GitHub file edits alone cannot confirm runtime/build status.

---

## Phase B — Settings + Setup Wizard + Connection

### Status

`In Progress`

### Goal

البرنامج يشتغل عند عميل جديد بدون تدخل يدوي.

### Planned Tasks

- [x] Build Settings home screen.
- [ ] Build Company Settings screen.
- [ ] Build Tax Settings screen.
- [ ] Build Database/Connection Settings screen.
- [ ] Build Backup Settings screen.
- [ ] Build Printer Settings screen.
- [ ] Build Users/Permissions screen.
- [ ] Build Setup Wizard.
- [ ] Add backend setup status endpoint if missing.
- [ ] Add initialize company endpoint if missing.
- [ ] Add default accounts seeding flow.
- [ ] Add first admin user flow.

### Already Done

- [x] Added settings models:
  - `RuntimeSettingsModel`
  - `CompanySettingsModel`
- [x] Added settings repository reading existing API endpoints:
  - `GET /api/settings/runtime`
  - `GET /api/settings/company`
- [x] Added settings providers:
  - `runtimeSettingsProvider`
  - `companySettingsProvider`
- [x] Added Settings Home screen:
  - `QuickBooksFlutter/ledgerflow/lib/features/settings/screens/settings_home_screen.dart`
- [x] Wired `/settings` route to `SettingsHomeScreen` instead of `ComingSoonScreen`.

### Current Phase B Notes

- Settings Home currently reads and displays runtime/company summary.
- Internal settings tiles still open `ComingSoonScreen` until each sub-screen is implemented.
- Next priority: Connection Settings screen, then Company Settings screen.

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

## Parallel Work Policy

لو حد دخل يشتغل معانا لاحقًا، الأفضل يتوزع على شغل لا يكسر المعمارية:

### Good Parallel Tasks

- UI mockups.
- PDF templates.
- Report styling.
- Documentation.
- Manual testing scenarios.
- Icons/assets/branding.
- Installer research.
- Demo data preparation.

### Needs Review Before Merge

- Backend entities.
- Posting logic.
- Database migrations.
- Router changes.
- Auth/security.
- Financial reports.

---

## Latest Progress Log

### 2026-05-04

- Added roadmap file.
- Added progress tracker file.
- Added local verification checklist.
- Wired missing transaction routes.
- Wired dashboard/top-menu/sidebar navigation.
- Added shared `ComingSoonScreen`.
- Replaced hardcoded transaction routes in key screens.
- Started Phase B.
- Added settings models/repository/providers.
- Added real Settings Home screen.
- Wired `/settings` to the new Settings Home screen.
- Next focus: Connection Settings screen and Company Settings screen.
