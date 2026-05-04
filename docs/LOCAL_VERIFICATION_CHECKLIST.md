# LedgerFlow / QuickBooksClone — Local Verification Checklist

> استخدم الملف ده بعد سحب آخر تعديلات من فرع `local-update` للتأكد إن المشروع لسه شغال بعد أي cleanup أو routing changes.

---

## 1. Pull Latest Changes

```bash
git checkout local-update
git pull
```

---

## 2. Backend Verification

### 2.1 Restore Packages

من جذر الريبو:

```bash
dotnet restore
```

### 2.2 Build Backend

```bash
dotnet build
```

### 2.3 Run API

ادخل على مشروع الـ API حسب مكانه الفعلي عندك، ثم شغل:

```bash
dotnet run
```

### 2.4 Confirm API

افتح Swagger أو endpoint الصحة لو موجود.

Expected:

- API starts without exceptions.
- Database connection succeeds.
- Migrations apply if auto-migration is enabled.
- Login endpoint works.

---

## 3. Flutter Verification

### 3.1 Go To Flutter App

```bash
cd QuickBooksFlutter/ledgerflow
```

### 3.2 Get Packages

```bash
flutter pub get
```

### 3.3 Analyze

```bash
flutter analyze
```

### 3.4 Run App

Windows/Desktop:

```bash
flutter run -d windows
```

Web/Chrome if needed:

```bash
flutter run -d chrome
```

---

## 4. Smoke Test — Login & Shell

Check:

- Login screen opens.
- Successful login redirects to dashboard.
- Sidebar appears.
- Top menu appears.
- Dashboard flowchart appears.
- Switching Arabic/English still works if language setting exists.

---

## 5. Smoke Test — Main Navigation

Open these routes from the UI:

### Dashboard / Shell

- Home Dashboard.
- Sidebar collapse/expand.
- Top menu dropdowns.

### Master Data

- Items.
- New Item.
- Vendors.
- New Vendor.
- Customers.
- New Customer.
- Chart of Accounts.
- New Account.

### Sales

- Estimates.
- Sales Orders.
- Sales Receipts.
- New Sales Receipt.
- Invoices.
- New Invoice.
- Payments.
- New Payment.
- Customer Credits.
- New Customer Credit.
- Sales Returns.
- New Sales Return.

### Purchases

- Purchase Orders.
- New Purchase Order.
- Receive Inventory.
- New Receive Inventory.
- Purchase Bills.
- New Purchase Bill.
- Vendor Payments.
- New Vendor Payment.
- Vendor Credits.
- New Vendor Credit.
- Purchase Returns.
- New Purchase Return.

### Company / Reports / Placeholders

- Reports.
- Journal Entries.
- Inventory Adjustments.
- Settings placeholder.
- Banking placeholders.
- Payroll placeholder.
- Calendar/Snapshots/Cash Flow Hub placeholders.

Expected:

- No route should send the user back to dashboard silently.
- Unfinished modules should show `ComingSoonScreen`.
- Real modules should open their list/form screens.

---

## 6. Smoke Test — Dynamic Details Routes

Check at least one existing record for:

- Invoice details.
- Sales Receipt details.
- Purchase Order details.
- Receive Inventory details.
- Item details.
- Vendor details.
- Customer details.
- Account edit.

Expected:

- Clicking a list card opens the correct details/edit screen.
- No `unknown route` / blank page.

---

## 7. Known Current Gaps

These are not Phase A blockers, but they are tracked for later phases:

- Purchase Bill list has an `onTap` TODO and no Purchase Bill details route yet.
- Banking screens are placeholders.
- Settings screen is placeholder.
- Payroll/Time Tracking are placeholders.
- Cash Flow Hub/Snapshots/Open Windows/My Company are placeholders.
- Printing/export is not yet unified.
- Setup Wizard is not started yet.

---

## 8. What To Send Back After Testing

Send:

1. Full output of:

```bash
dotnet build
```

2. Full output of:

```bash
flutter analyze
```

3. Screenshot or copy of first runtime exception if the app opens then crashes.

4. Name of the route/screen that fails, if any.

---

## 9. Decision Before Commercial Release

Before starting packaging/selling, decide:

- Keep `.NET 10` or move to `.NET 8 LTS`.
- First release: SQLite only or SQLite + SQL Server.
- Hide unfinished modules or show `Coming Soon`.
- First commercial edition name: Solo / Pro / Network.
