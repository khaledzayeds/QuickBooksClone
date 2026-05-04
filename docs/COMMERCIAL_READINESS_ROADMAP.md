# LedgerFlow / QuickBooksClone — Commercial Readiness Roadmap

> الهدف من الملف ده: تحويل المشروع من كود شغال وموديولات متفرقة إلى نظام تجاري متكامل جاهز للبيع والتثبيت عند العملاء.
>
> الفرع المرجعي الحالي: `local-update`

---

## 1. Current High-Level Assessment

المشروع حاليًا ليس مجرد تجربة. الأساس قوي وقريب من ERP / POS Accounting System حقيقي.

### الموجود حاليًا

- Flutter front-end باستخدام:
  - Riverpod
  - GoRouter
  - Dio
  - Localization عربي/إنجليزي
  - Theme system
- ASP.NET API منظم إلى:
  - `QuickBooksClone.Api`
  - `QuickBooksClone.Core`
  - `QuickBooksClone.Infrastructure`
- EF Core persistence.
- SQLite كقاعدة افتراضية.
- دعم SQL Server من ناحية packages والمشروع، لكنه محتاج strategy واضحة للتشغيل التجاري.
- Posting services للمعاملات المهمة.
- Security / Auth / Permissions.
- Reports أساسية قوية:
  - Trial Balance
  - Balance Sheet
  - Profit & Loss
  - Accounts Receivable Aging
  - Accounts Payable Aging
  - Inventory Valuation
  - Tax Summary

### الحكم العام

المشروع قريب من منتج تجاري، لكنه ليس جاهزًا للبيع قبل إكمال:

1. Stability.
2. Setup wizard.
3. Settings UI.
4. Printing and export.
5. Banking/Reconciliation.
6. Backup/Restore UI.
7. Licensing/Activation.
8. Installer/Packaging.
9. UX polish.

---

## 2. Backend Status

### 2.1 Strengths

#### Architecture

الباك إند منظم بشكل جيد:

- API layer للـ controllers.
- Core layer للـ domain/interfaces.
- Infrastructure layer للـ EF repositories/services.

`Program.cs` يسجل موديولات كثيرة، منها:

- Accounts
- Customers
- Vendors
- Items
- Invoices
- Payments
- Purchase Bills
- Purchase Orders
- Receive Inventory
- Reports
- Security
- Taxes
- Sync
- Sales Returns
- Purchase Returns
- Vendor Credits
- Customer Credits
- Vendor Payments
- Journal Entries
- Inventory Adjustments

#### Posting Engine

يوجد منطق posting فعلي، وليس مجرد CRUD.

الموجود:

- Create/Save.
- SaveAndPost.
- Post.
- Void.
- Reversal transaction references في بعض الموديولات.

ده اتجاه صحيح جدًا لنظام QuickBooks-like.

#### Reports

التقارير الموجودة مهمة تجاريًا:

- ميزان مراجعة.
- قائمة مركز مالي.
- أرباح وخسائر.
- أعمار مديونية العملاء.
- أعمار مديونية الموردين.
- تقييم مخزون.
- ملخص ضريبة.

#### Security

يوجد:

- Login.
- Logout.
- Me endpoint.
- Set password.
- Bearer token/session.
- Permissions middleware.
- Roles/permissions في الداتا موديل.

#### Database Scope

قاعدة البيانات تحتوي موديولات مهمة:

- Accounts.
- Accounting Transactions.
- Customers.
- Vendors.
- Items.
- Invoices.
- Payments.
- Purchase Bills.
- Purchase Orders.
- Inventory Receipts.
- Sales Returns.
- Purchase Returns.
- Security.
- Settings.
- Tax Codes.
- Vendor Payments.
- Customer Credits.
- Vendor Credits.

---

## 3. Backend Gaps Before Commercial Release

### 3.1 Target Framework Decision

المشروع حاليًا مستهدف `.NET 10.0`.

#### المطلوب

تحديد قرار واضح:

- إما الاستمرار على `.NET 10` لو البيئة عندك ثابتة ومقصودة.
- أو التحويل إلى `.NET 8 LTS` للنسخة التجارية، لأن LTS أسهل في التثبيت والدعم عند العملاء.

#### Recommendation

للبيع التجاري: الأفضل `.NET 8 LTS` إلا لو في سبب قوي للـ `.NET 10`.

---

### 3.2 Database Editions

الإعداد الحالي يستخدم SQLite افتراضيًا:

```json
"Provider": "Sqlite",
"Data Source=quickbooksclone.db"
```

#### المطلوب

تقسيم المنتج إلى Editions:

1. Solo Edition
   - SQLite local.
   - مستخدم واحد أو جهاز واحد.

2. Network Edition
   - SQL Server.
   - أكثر من جهاز على نفس الشبكة.

3. Hosted Edition لاحقًا
   - API hosted.
   - SQL Server/PostgreSQL.

#### Required Work

- شاشة اختيار database mode.
- Test connection.
- Save database profile.
- Backup directory.
- Migration runner واضح.
- Error messages مفهومة عند فشل الاتصال.

---

### 3.3 Banking Module

حاليًا فيه placeholders في الراوتر للآتي:

- Make Deposits.
- Write Checks.
- Reconcile.

لكن موديول Banking التجاري غير مكتمل.

#### المطلوب في Banking

Backend:

- BankAccount entity أو استخدام Account مع type Bank مع جداول حركة مخصصة.
- Deposit entity.
- Check/ExpensePayment entity.
- BankTransfer entity.
- BankStatement entity.
- BankStatementLine entity.
- BankReconciliation entity.
- ReconciliationLine entity.
- Posting services.
- Void/reversal support.

Frontend:

```text
features/banking/
  data/
    datasources/
    models/
    repositories/
  providers/
  screens/
    bank_account_list_screen.dart
    deposit_form_screen.dart
    check_form_screen.dart
    transfer_form_screen.dart
    reconciliation_screen.dart
    statement_import_screen.dart
```

#### MVP Banking

1. Make Deposit.
2. Write Check.
3. Bank Transfer.
4. Basic Reconciliation.

---

### 3.4 Cash Drawer / POS Shift

لو النظام هيتباع لمحل أو تجارة، لازم موديول ورديات.

#### المطلوب

- Open shift.
- Close shift.
- Starting cash.
- Cash sales.
- Cash payments.
- Cash expenses.
- Expected cash.
- Counted cash.
- Difference.
- Shift report.

#### Suggested Structure

Backend:

```text
Core/CashRegister/
Infrastructure/CashRegister/
Api/Controllers/CashShiftsController.cs
```

Frontend:

```text
features/cash_register/
features/shifts/
```

---

### 3.5 Multi-Warehouse / Inventory Locations

الحالي يبدو مناسبًا لمخزون عام أو QuantityOnHand، لكنه لا يكفي لنسخة تجارية قوية متعددة المخازن.

#### المطلوب

- InventoryLocation.
- ItemStockByLocation.
- StockTransfer.
- StockCount.
- StockAdjustment per location.
- Low stock alerts per location.

#### MVP

- Location master.
- Quantity per item/location.
- Transfer between locations.

---

### 3.6 Payroll / Employees

الواجهة حاليًا فيها:

- Enter Time placeholder.
- Payroll placeholder.

#### القرار المطلوب

إما:

1. نخفي Payroll من أول نسخة تجارية.
2. أو نعمل MVP بسيط.

#### MVP Payroll

- Employees.
- Time entries.
- Salary/Hourly rate.
- Payroll run.
- Payroll expense posting.

---

### 3.7 Licensing / Activation

ده غير واضح أنه موجود، لكنه ضروري للبيع.

#### المطلوب

Backend:

- License entity.
- Activation entity.
- Device fingerprint.
- Trial status.
- Expiry date.
- Plan limits.
- Offline grace period.

Frontend:

```text
features/licensing/
  screens/license_activation_screen.dart
  screens/license_status_screen.dart
```

#### Business Requirements

- Trial 14/30 days.
- License key.
- Device activation.
- Deactivate device.
- Offline usage grace period.
- Plan name: Solo / Pro / Network.

---

### 3.8 Backup / Restore UI

الباك فيه إشارات لدعم runtime/database maintenance، لكن الواجهة ناقصة.

#### المطلوب

Frontend:

- Backup now.
- Restore backup.
- Auto backup settings.
- Backup directory.
- Last backup status.
- Backup schedule.

Backend:

- Backup endpoint.
- Restore endpoint.
- Validate backup endpoint.
- List backups endpoint.

---

## 4. Flutter Frontend Status

### 4.1 Strengths

- Riverpod مناسب لإدارة الحالة.
- GoRouter مناسب للتنقل.
- Dio موجود في ApiClient.
- Localization موجود.
- Theme موجود.
- Router أصبح أوضح بعد ربط الشاشات الناقصة.

### 4.2 Current Important Routes

الموصل حاليًا:

Sales:

- Estimates.
- Sales Orders.
- Sales Receipts.
- Invoices.
- Payments.
- Customer Credits.
- Sales Returns.

Purchases:

- Purchase Orders.
- Receive Inventory.
- Purchase Bills.
- Vendor Payments.
- Vendor Credits.
- Purchase Returns.

Master Data:

- Items.
- Vendors.
- Customers.
- Chart of Accounts.

Company / Inventory / Reports:

- Inventory Adjustments.
- Journal Entries.
- Reports.
- Settings placeholder.

---

## 5. Flutter Gaps Before Commercial Release

### 5.1 Connection Settings

الحالي في `AppConstants`:

```text
localhost
192.168.1.x
your-server.com
```

ده لا يصلح كمنتج تجاري.

#### المطلوب

شاشة Connection Settings:

- Local server.
- LAN server.
- Hosted server.
- Base URL input.
- Test connection.
- Save profile.
- Auto reconnect.
- Server disconnected banner.

Suggested structure:

```text
features/connection/
  data/
  providers/
  screens/connection_settings_screen.dart
```

---

### 5.2 Settings Screen

`/settings` حاليًا placeholder.

#### المطلوب

Settings UI كامل:

- Company info.
- Language.
- Currency.
- Tax settings.
- Fiscal year.
- Default accounts.
- Database settings.
- Backup settings.
- Printer settings.
- Users and permissions.
- Theme/appearance.

Suggested structure:

```text
features/settings/
  data/
  providers/
  screens/
    settings_home_screen.dart
    company_settings_screen.dart
    tax_settings_screen.dart
    database_settings_screen.dart
    backup_settings_screen.dart
    printer_settings_screen.dart
    users_permissions_screen.dart
```

---

### 5.3 Setup Wizard

لازم أول تشغيل يكون guided.

#### المطلوب

```text
features/setup_wizard/
  screens/
    welcome_step.dart
    company_step.dart
    currency_language_step.dart
    tax_step.dart
    database_step.dart
    default_accounts_step.dart
    admin_user_step.dart
    finish_step.dart
```

#### Flow

1. Welcome.
2. Company information.
3. Language + currency.
4. Tax enabled/disabled.
5. Fiscal year.
6. Default accounts.
7. Database mode.
8. Admin user.
9. Finish and login.

---

### 5.4 Navigation Cleanup

حاليًا فيه placeholders واضحة للآتي:

```text
/settings
/banking/deposits
/banking/checks
/banking/reconcile
/company/payroll
/company/time-tracking
/company/calendar
/company/snapshots
/company/cash-flow-hub
/company/profile
/company/open-windows
```

#### المطلوب

قرار لكل route:

- Build now.
- Hide temporarily.
- Keep as Coming Soon.
- Move to Pro Edition.

---

### 5.5 Reports UI Polish

التقارير موجودة، لكن UI محتاج تحسين.

#### المطلوب

- أسماء تقارير دقيقة:
  - Balance Sheet.
  - Trial Balance.
  - Profit & Loss.
  - AR Aging.
  - AP Aging.
  - Inventory Valuation.
  - Tax Summary.
- Date filters.
- Refresh button.
- Export PDF.
- Export Excel/CSV.
- Print.
- Column alignment.
- Currency formatting.
- Arabic RTL tables.

---

### 5.6 Unified Error Handling

#### المطلوب

- Global API error mapper.
- Unauthorized auto logout.
- Server disconnected banner.
- Retry buttons.
- Empty states.
- Loading skeletons.
- Form validation messages.
- Friendly error dialogs.

Suggested structure:

```text
core/errors/
core/widgets/app_error_view.dart
core/widgets/app_empty_state.dart
core/widgets/app_loading_view.dart
```

---

### 5.7 Printing / Export

ده ضروري جدًا للبيع.

#### المطلوب

- Invoice A4.
- Receipt 80mm.
- Sales receipt print.
- Purchase bill print.
- Customer statement.
- Vendor statement.
- Journal entry print.
- Reports PDF.
- Reports Excel/CSV.
- Company logo.
- Arabic RTL.
- Template settings.

Suggested structure:

```text
core/printing/
  pdf_service.dart
  thermal_printer_service.dart
  print_preview_screen.dart
features/documents/templates/
```

---

## 6. Files / Areas That Are Temporary or Need Completion

### 6.1 Confirmed Temporary Routes

- Settings.
- Banking Deposits.
- Banking Checks.
- Banking Reconcile.
- Payroll.
- Enter Time.
- Calendar.
- Snapshots.
- Cash Flow Hub.
- My Company.
- Open Windows.

### 6.2 Files To Review/Clean

Run a repository cleanup pass to find and remove or merge:

- `*_fixed.dart`.
- `*_fixed_v2.dart`.
- `router_fixed.dart`.
- `router_full_fixed.dart`.
- old `Errors.txt`.
- duplicated screens.
- unused imports.
- hardcoded routes inside screens.
- hardcoded Arabic/English labels not in localization.

### 6.3 Hardcoded Paths To Replace

Some screens still use direct paths like:

```dart
context.go('/sales/returns/new')
context.go('/purchases/returns/new')
context.go('/sales/customer-credits/new')
context.go('/purchases/vendor-credits/new')
```

#### المطلوب

Replace with:

```dart
AppRoutes.salesReturnNew
AppRoutes.purchaseReturnNew
AppRoutes.customerCreditNew
AppRoutes.vendorCreditNew
```

---

## 7. Commercial Product Roadmap

## Phase 0 — Stabilization / Build Lock

### Goal

تثبيت المشروع وبناء نسخة developer stable.

### Tasks

- Run backend build:

```bash
dotnet build
```

- Run Flutter analysis:

```bash
flutter analyze
```

- Run tests if available:

```bash
flutter test
dotnet test
```

- Fix all compile errors.
- Fix all missing imports.
- Fix localization errors.
- Remove old temporary files.
- Remove old error logs.
- Confirm router works.
- Confirm login flow works.
- Confirm API starts and migrations apply.

### Deliverable

- Clean build.
- Clean analyzer or known accepted warnings list.
- Developer README.

---

## Phase 1 — Setup Wizard + Settings

### Goal

البرنامج يشتغل عند عميل جديد بدون تدخل يدوي منك.

### Tasks

- Build setup wizard.
- Build settings module.
- Add setup status endpoint.
- Add initialize company endpoint.
- Add admin user creation step.
- Add default accounts setup.
- Add tax setup.
- Add database mode setup.
- Add backup folder setup.

### Backend Needed

- SetupController.
- SetupStatusDto.
- InitializeCompanyRequest.
- Seed default accounts.
- Seed default roles.
- Seed default tax codes optional.

### Frontend Needed

```text
features/setup_wizard/
features/settings/
```

### Deliverable

- First-run experience.
- Working settings screen.

---

## Phase 2 — Navigation Product Cleanup

### Goal

لا يوجد زرار يودي لمكان غامض أو يرجع للداشبورد بدون سبب.

### Tasks

- Build `ComingSoonScreen` موحد.
- Hide unfinished modules from release mode.
- Add feature flags.
- Replace hardcoded labels with localization.
- Replace hardcoded routes with `AppRoutes`.
- Review Dashboard.
- Review Sidebar.
- Review TopMenu.

### Deliverable

- Professional navigation.
- No confusing placeholders.

---

## Phase 3 — Commercial Core MVP

### Goal

نسخة تجارية أساسية قابلة للبيع كـ Accounting + Inventory + Sales/Purchases.

### Modules To Complete

1. Customers.
2. Vendors.
3. Items.
4. Chart of Accounts.
5. Invoices.
6. Sales Receipts.
7. Payments.
8. Purchase Orders.
9. Receive Inventory.
10. Purchase Bills.
11. Vendor Payments.
12. Sales Returns.
13. Purchase Returns.
14. Customer Credits.
15. Vendor Credits.
16. Inventory Adjustments.
17. Journal Entries.
18. Reports.

### Every Module Must Have

- List screen.
- Search.
- Filters.
- Create form.
- Details screen.
- Edit if allowed.
- Post/void if relevant.
- Print/export.
- Empty state.
- Error state.
- Loading state.

### Deliverable

- Sellable MVP.

---

## Phase 4 — Printing & Documents

### Goal

كل مستند مهم يطلع PDF/Print بشكل احترافي.

### Tasks

- A4 invoice template.
- 80mm receipt template.
- Sales receipt template.
- Purchase bill template.
- Customer statement.
- Vendor statement.
- Report PDF templates.
- Company logo support.
- Arabic RTL support.
- Print preview.
- Printer settings.

### Deliverable

- Print-ready system.

---

## Phase 5 — Banking

### Goal

إكمال جزء Banking الأساسي حتى يصبح النظام قريب من QuickBooks.

### Tasks

- Bank accounts.
- Make deposits.
- Write checks.
- Transfers.
- Bank reconciliation.
- CSV/Excel statement import.
- Reconciliation reports.

### Deliverable

- Banking MVP.

---

## Phase 6 — Inventory Pro

### Goal

تقوية المخزون للنسخة الاحترافية.

### Tasks

- Warehouses/locations.
- Stock per location.
- Transfers.
- Stock count.
- Low stock alerts.
- Inventory movement report.
- Costing strategy review.

### Deliverable

- Inventory Pro module.

---

## Phase 7 — Security, Licensing, Installer

### Goal

تحويل النظام إلى منتج قابل للبيع والتوزيع.

### Security Tasks

- Users screen.
- Roles screen.
- Permissions editor.
- Change password.
- Audit log viewer.
- Session management.

### Licensing Tasks

- License key.
- Activation screen.
- Device activation.
- Trial period.
- Offline grace period.
- Plan limits.

### Installer Tasks

- Windows installer.
- Start API with app.
- Database folder selection.
- Backup folder selection.
- Desktop shortcut.
- Update mechanism لاحقًا.

### Deliverable

- Commercial release candidate.

---

## 8. Recommended Immediate Next Steps

### Step 1 — Pull latest branch when ready

```bash
git checkout local-update
git pull
```

### Step 2 — Run build checks

```bash
dotnet build
flutter analyze
```

### Step 3 — Send build output

أي errors تظهر من الأمرين دول يتم إصلاحها أولًا.

### Step 4 — Start Phase 0 Cleanup

- Remove temporary files.
- Fix hardcoded routes.
- Fix analyzer errors.
- Fix localization issues.
- Make router stable.

### Step 5 — Start Phase 1

- Setup Wizard.
- Settings screen.
- Company setup.
- Database setup.
- Admin user setup.

---

## 9. Definition of Done For First Sellable Version

النسخة الأولى تعتبر قابلة للبيع لما تحقق الآتي:

### Technical

- `dotnet build` بدون errors.
- `flutter analyze` بدون blocking errors.
- API starts reliably.
- Flutter connects to API.
- Login works.
- Migrations apply automatically.
- Backup works.

### Product

- First-run setup wizard.
- Company settings.
- Users/permissions basics.
- Sales workflow works.
- Purchase workflow works.
- Inventory basics work.
- Accounting posting works.
- Reports work.
- Print/PDF works.

### Commercial

- Installer.
- License activation.
- Trial mode.
- Backup/restore.
- Documentation.
- Basic support guide.

---

## 10. Priority Order

الترتيب المقترح للتنفيذ:

1. Build stability.
2. Cleanup temporary files.
3. Settings screen.
4. Setup wizard.
5. Connection settings.
6. Printing/PDF.
7. Reports polish.
8. Backup/restore UI.
9. Users/roles UI.
10. Licensing.
11. Installer.
12. Banking.
13. Inventory Pro.
14. Payroll.

---

## 11. Notes For Future Development

- لا تضيف موديولات جديدة قبل تثبيت البناء.
- أي route جديد لازم يتسجل في `AppRoutes` فقط، وليس hardcoded داخل الشاشات.
- أي نص ظاهر للمستخدم لازم يدخل localization.
- أي transaction مالية لازم يكون لها status واضح:
  - Draft.
  - Saved.
  - Posted.
  - Voided.
- أي posted transaction لازم يكون لها reversal/void strategy.
- أي شاشة قائمة لازم تحتوي search/filter/empty/error/loading.
- أي مستند مالي لازم يدعم print/export.
- أي feature غير مكتملة لا تظهر للعميل إلا كـ Coming Soon واضح أو تكون مخفية من release build.

---

## 12. Immediate Work Package Proposal

أول باكدج شغل نبدأ به:

### Work Package 1 — Stabilization and Cleanup

#### Tasks

- Run `dotnet build`.
- Run `flutter analyze`.
- Fix errors.
- Remove `Errors.txt` لو قديم.
- Remove duplicated router/fixed files.
- Replace hardcoded transaction routes.
- Confirm all connected screens open.
- Confirm auth redirect works.

#### Expected Result

نسخة مستقرة نقدر نبني فوقها بثقة.

### Work Package 2 — Settings + Setup Wizard

#### Tasks

- Build settings home.
- Build company settings UI.
- Build database/connection settings UI.
- Build setup wizard.
- Add missing backend setup endpoints if needed.

#### Expected Result

برنامج يفتح عند عميل جديد ويعمل setup كامل.

---

## Final Product Vision

الهدف النهائي:

> LedgerFlow يكون نظام محاسبة ومخزون ومبيعات ومشتريات احترافي، يعمل محليًا أو على شبكة داخلية، يدعم العربي والإنجليزي، يطبع فواتير وتقارير، يحافظ على الحسابات بالـ posting engine، ويدار بصلاحيات ونسخ احتياطي وترخيص تجاري.
