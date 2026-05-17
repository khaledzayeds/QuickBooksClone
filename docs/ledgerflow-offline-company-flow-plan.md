# LedgerFlow Offline Company Flow & Setup Wizard Plan

This document is the shared implementation plan for ChatGPT/Codex work on the `ledgerflow/offline` branch.

The goal is to stop patching the first-run flow and implement a clear QuickBooks-style offline desktop experience.

---

## 1. Non-negotiable flow

LedgerFlow Offline must have three separate concepts and three separate routes:

```text
/companies  = No Company Open / Recent Companies / Open Company File
/setup      = Setup Wizard for the currently opened company file
/login      = Login for the currently opened and initialized company
```

Rules:

1. The app starts at `/companies`.
2. If no active company is open, the user must stay on `/companies`.
3. The user must never see `/setup` unless a company file is active/open.
4. The user must never see `/login` unless a company file is active/open.
5. If an active company is open but not initialized, route to `/setup`.
6. If an active company is open and initialized, route to `/login`.
7. `LoginScreen` must only be a login form. It must not render `CompanyLauncherScreen` internally.
8. `CompanyLauncherScreen` must be a first-class route at `/companies`.
9. `Switch Company` must close the active company and route to `/companies` without deleting recent companies.
10. Setup success must confirm `/api/setup/status` returns `isInitialized=true`, then route to `/login`.

---

## 2. QuickBooks-style No Company Open screen

The first screen should resemble QuickBooks "No Company Open".

Target layout:

```text
No Company Open
Select a company that you've previously opened and click Open

[ Recent companies table/list ]     [Open]
                                    [Edit List]

Location: C:/Users/.../Documents/LedgerFlow/Companies

[Create a new company] [Open or restore an existing company] [Open a sample file] [Find a company file]
```

Minimum fields in recent companies:

- Company Name
- Last Modified / Last Opened
- File Size
- Path tooltip or secondary line

Actions:

- `Open`: opens selected recent company.
- `Create a new company`: creates/selects a `.ledgerflow` file, registers it, opens backend runtime, then goes to setup.
- `Open or restore an existing company`: file picker for `.ledgerflow` and `.db`; if chosen, register/open it.
- `Find a company file`: file picker/search action.
- `Edit List`: remove from recent list only; never delete actual company DB file unless explicit future feature.

---

## 3. Setup Wizard scope

The setup wizard must be more than one plain form. It should gather the settings needed to seed accounting correctly.

Wizard steps:

### Step 1 — Company profile

- Company name
- Legal name
- Country
- Currency
- Timezone
- Default language
- Email
- Phone
- Address fields later if needed

### Step 2 — Fiscal year

- Fiscal year start month
- Fiscal year start day
- First accounting period start date
- Lock date optional later

This must feed company settings and reporting periods.

### Step 3 — Taxes

- Taxes enabled: yes/no
- Prices include tax: yes/no
- Default sales tax rate
- Default purchase tax rate
- Tax rounding mode: per line / per transaction
- Default sales tax payable account
- Default purchase tax receivable account

If taxes enabled, seed default tax codes and GL accounts.

### Step 4 — Inventory and warehouses

- Inventory enabled: yes/no
- Default inventory location/warehouse name
- Advanced inventory enabled: future/license-controlled
- Reorder tracking enabled: optional

If inventory enabled, seed:

- Inventory Asset
- COGS
- Inventory Adjustment
- Inventory Received Not Billed / GRNI
- Default warehouse/location

### Step 5 — Services/items behavior

- Services enabled: yes/no
- Non-inventory items enabled: yes/no
- Default income account
- Default expense account
- Default COGS account
- Default inventory asset account

### Step 6 — Users

- Admin username
- Admin display name
- Admin email
- Admin password/secret
- Confirm password

### Step 7 — Review and create

Show a review page before POSTing initialize.

On Finish:

1. POST `/api/setup/initialize-company`.
2. Refresh `/api/setup/status`.
3. If `isInitialized=true`, navigate to `/login`.
4. If false/null/error, show a clear visible error. Never spin forever.

---

## 4. Chart of Accounts seeding logic

Setup must drive the default Chart of Accounts.

Base accounts to seed for all companies:

- Cash on Hand
- Bank/Cash default account
- Accounts Receivable
- Accounts Payable
- Owner Equity
- Opening Balance Equity
- Sales Income
- General Expenses

If taxes enabled:

- Sales Tax Payable
- Input VAT Receivable / Purchase Tax Receivable
- Default Sales VAT tax code
- Default Purchase VAT tax code

If inventory enabled:

- Inventory Asset
- Cost of Goods Sold
- Inventory Adjustment Expense
- Inventory Received Not Billed / GRNI

If services enabled:

- Service Income
- Service Expense / Contractors Expense if needed

Important: account names can be refined later, but setup flags must decide which accounts exist.

---

## 5. Backend rules

The backend must treat the selected company file as the active database.

Required behavior:

1. `POST /api/companies/open` receives `databasePath` and stores it in runtime.
2. DbContext must use `ICompanyRuntimeService.Current.DatabasePath` when active.
3. If no active company is open, setup/status returns not initialized.
4. Opening a company must ensure schema exists or migrations are applied.
5. `/api/setup/status` must read from the active company DB.
6. `/api/setup/initialize-company` must write to the active company DB.
7. `/api/setup` endpoints must not be wrapped by `TransactionalWriteMiddleware` before schema exists.
8. Setup initialization must return a response or a handled error. No silent hangs.
9. Database file creation should be explicit and safe; if directory does not exist, create it.

---

## 6. Flutter routing rules

Use deterministic routing:

```dart
final path = state.uri.path;
final isCompaniesRoute = path == AppRoutes.companies;
final isSetupRoute = path == AppRoutes.setup;
final isLoginRoute = path == AppRoutes.login;

if (companyRegistryState is AsyncLoading) return null;

final hasActiveCompany = companyRegistryState.value?.activeCompany != null;
if (!hasActiveCompany) {
  return isCompaniesRoute ? null : AppRoutes.companies;
}

if (setupState is AsyncLoading) return null;

if (setupState.hasError) {
  return isSetupRoute ? null : AppRoutes.setup;
}

final setup = setupState.value;
if (setup != null && !setup.isInitialized) {
  return isSetupRoute ? null : AppRoutes.setup;
}

if (setup != null && setup.isInitialized && (isSetupRoute || isCompaniesRoute)) {
  return AppRoutes.login;
}

if (authState is AsyncLoading) return null;

final isLoggedIn = authState.value != null;
if (!isLoggedIn && !isLoginRoute && !isSetupRoute && !isCompaniesRoute) {
  return AppRoutes.login;
}

if (isLoggedIn && isLoginRoute) return AppRoutes.dashboard;
return null;
```

---

## 7. Work boundaries for agents

When working on this flow:

- Do not refactor the entire app.
- Do not touch print templates.
- Do not redesign all settings.
- Do not change all repositories at once.
- Keep each commit focused.
- First make `/companies -> /setup -> /login` stable.
- Then improve UI to match QuickBooks.
- Then expand setup wizard steps.
- Then harden DB switching and packaging.

---

## 8. Acceptance tests

Manual test 1: clean first run

1. Clear local app preferences or use Switch Company.
2. Start app.
3. App opens `/companies`.
4. Create new company file.
5. App opens `/setup`.
6. Fill wizard.
7. Initialize succeeds.
8. App opens `/login`.
9. Login with created admin user.
10. Dashboard opens.

Manual test 2: app restart

1. Close app and API.
2. Start app again.
3. Recent company appears.
4. Open recent company.
5. If initialized, app goes `/login` not `/setup`.

Manual test 3: switch company

1. On login, click Switch Company.
2. Active company closes.
3. App goes `/companies`.
4. Recent companies remain listed.
5. No company file is deleted.

Manual test 4: no active company

1. Force navigate to `/setup` with no active company.
2. Router sends user to `/companies`.
3. Setup screen must not show "No active company is open" as a normal state.

---

## 9. Immediate next tasks

1. Verify `AppRoutes.companies` exists and is the initial location.
2. Verify `LoginScreen` no longer imports or renders `CompanyLauncherScreen`.
3. Verify `Switch Company` closes active company and routes to `/companies`.
4. Verify `/api/setup` is excluded from `TransactionalWriteMiddleware`.
5. Verify setup POST + status refresh can navigate to `/login`.
6. Replace the launcher UI with a closer QuickBooks-style table/actions layout.
7. Convert SetupScreen from a single long form to a multi-step wizard.
