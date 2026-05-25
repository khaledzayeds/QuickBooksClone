# Zayed Offline ERP v1 Release Notes

## Included Workflows

- Local company file creation/opening
- First-run setup and login foundation
- Customers, vendors, items, accounts
- Sales receipt, invoice, customer payment
- Purchase order, receive inventory, purchase bill, vendor payment
- Core reports, including trial balance, profit and loss, and balance sheet
- Backup/restore flow when the installed license allows it
- Default invoice/receipt printing flow
- Arabic and English UI foundation

## Offline v1 Limitations

- Windows desktop only
- Local API and SQLite database only
- SQL Server is not v1 production-ready
- Sync is deferred
- Payroll is deferred and license-gated
- Advanced inventory is deferred
- LAN/hosted modes are deferred

## Install And Run

Run `Zayed.exe` from the release folder. The app starts the bundled local service from `api/Zayed.Api.exe`. If service files are missing, reinstall from a clean release folder.

## Known QA Requirement

Before shipping, complete `scripts/manual-v1-qa-checklist.md` and update `COMMERCIAL_RELEASE_CHECKLIST.md` with pass/fail evidence.
