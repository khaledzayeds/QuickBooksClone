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

مش لازم كل phases تخلص قبل بداية أي تفكير في غيرها، لكن ممنوع نفتح موديول كبير جديد قبل ما مرحلة الاستقرار الأساسية تبقى واضحة.

---

## Working Rules

1. أي تعديل كبير يتسجل هنا.
2. أي route جديد لازم يتسجل في `AppRoutes`، ومش يبقى hardcoded جوه الشاشة.
3. أي feature غير مكتملة إما تتخفى أو تفتح `Coming Soon` واضح، مش ترجع للداشبورد.
4. أي شاشة تجارية لازم يكون فيها:
   - Loading state
   - Error state
   - Empty state
   - Search/filter لو List screen
   - Print/export لو مستند أو تقرير
5. أي نص ظاهر للمستخدم لازم يتحول لاحقًا إلى localization.
6. أي transaction مالية لازم يكون لها status واضح:
   - Draft
   - Saved
   - Posted
   - Voided
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
- [ ] Replace remaining hardcoded transaction routes with `AppRoutes`.
- [ ] Confirm all main routes open.
- [ ] Confirm auth redirect/login flow works.
- [ ] Confirm API starts and migrations apply.

### Already Done

- [x] Created commercial readiness roadmap: `docs/COMMERCIAL_READINESS_ROADMAP.md`.
- [x] Added missing transaction routes to `QuickBooksFlutter/ledgerflow/lib/app/router.dart`.
- [x] Wired routes for:
  - Sales Returns
  - Customer Credits
  - Purchase Returns
  - Vendor Credits
- [x] Added named placeholders for unfinished modules:
  - Settings
  - Make Deposits
  - Write Checks
  - Reconcile
  - Payroll
  - Enter Time
  - Calendar
  - Snapshots
  - Cash Flow Hub
  - My Company
  - Open Windows
- [x] Wired dashboard flowchart navigation.
- [x] Wired top menu navigation.
- [x] Wired sidebar navigation.
- [x] Created this progress tracker.

### Current Blockers

- Local build/analyze output is still needed from the developer machine because GitHub file edits alone cannot confirm runtime/build status.

### Next Action

Start cleanup pass:

1. Replace hardcoded paths inside transaction screens.
2. Add shared `ComingSoonScreen` instead of inline placeholder builder.
3. Review routing and navigation consistency.
4. Wait for local `dotnet build` and `flutter analyze` output when available.

---

## Phase B — Settings + Setup Wizard + Connection

### Status

`Not Started`

### Goal

البرنامج يشتغل عند عميل جديد بدون تدخل يدوي.

### Planned Tasks

- [ ] Build Settings home screen.
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

### Required For Each Module

- [ ] List screen
- [ ] Search
- [ ] Filters
- [ ] Create form
- [ ] Details screen
- [ ] Edit if allowed
- [ ] Post/Void if relevant
- [ ] Print/Export if relevant
- [ ] Empty state
- [ ] Error state
- [ ] Loading state

---

## Phase D — Printing + Reports + Backup

### Status

`Not Started`

### Goal

تجهيز النظام للطباعة والتقارير والنسخ الاحتياطي بشكل تجاري.

### Planned Tasks

- [ ] A4 invoice template.
- [ ] 80mm receipt template.
- [ ] Sales receipt print.
- [ ] Purchase bill print.
- [ ] Customer statement.
- [ ] Vendor statement.
- [ ] Journal entry print.
- [ ] Report PDF templates.
- [ ] Reports Excel/CSV export.
- [ ] Print preview.
- [ ] Company logo support.
- [ ] Arabic RTL support.
- [ ] Backup now UI.
- [ ] Restore backup UI.
- [ ] Backup schedule UI.

---

## Phase E — Licensing + Installer

### Status

`Not Started`

### Goal

تحويل البرنامج لمنتج قابل للبيع والتوزيع.

### Planned Tasks

- [ ] License key model.
- [ ] Activation screen.
- [ ] Trial mode.
- [ ] Device activation.
- [ ] Offline grace period.
- [ ] Plan limits.
- [ ] Windows installer.
- [ ] API auto-start with app.
- [ ] Database folder selection.
- [ ] Backup folder selection.
- [ ] Desktop shortcut.

---

## Phase F — Banking / Inventory Pro / Payroll

### Status

`Not Started`

### Banking Tasks

- [ ] Bank accounts.
- [ ] Make deposits.
- [ ] Write checks.
- [ ] Bank transfers.
- [ ] Reconciliation.
- [ ] Statement import.

### Inventory Pro Tasks

- [ ] Warehouses / locations.
- [ ] Stock per location.
- [ ] Stock transfers.
- [ ] Stock count.
- [ ] Low stock alerts.

### Payroll Tasks

- [ ] Employees.
- [ ] Time entries.
- [ ] Payroll run.
- [ ] Payroll expense posting.

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
- Wired missing transaction routes.
- Wired dashboard/top-menu/sidebar navigation.
- Next focus: Phase A cleanup and stability.
