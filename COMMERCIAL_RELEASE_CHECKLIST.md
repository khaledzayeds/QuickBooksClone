# Commercial Release Checklist - Zayed Offline ERP v1

Last updated: 2026-05-30 10:36 Africa/Cairo
Branch: `release/v1-zayed-offline`

## Automated Checks

- [x] Backend solution restore passed.
- [x] Backend solution build passed.
- [x] Core backend smoke passed, including Time Tracking.
- [x] `scripts/smoke-time-tracking.ps1` ran explicitly.
- [x] `scripts/smoke-company-runtime.ps1` role confirmed as a dot-sourced helper, not a standalone smoke.
- [x] Flutter `pub get` passed.
- [x] Flutter analyze ran and did not fail the release check.
- [x] Flutter Windows release build passed.
- [x] Windows release folder created.
- [x] Release folder contains `Zayed.exe`.
- [x] Release folder contains `api/Zayed.Api.exe`.

## Release Artifact

- Folder: `artifacts/ZayedOfflineERP-v1-win-x64/`
- App executable: `artifacts/ZayedOfflineERP-v1-win-x64/Zayed.exe`
- Bundled API executable: `artifacts/ZayedOfflineERP-v1-win-x64/api/Zayed.Api.exe`
- Launch result: app process started from the release folder and bundled `Zayed.Api.exe` started automatically from the release folder.
- API health from artifact: `GET http://127.0.0.1:5014/api/health` returned `status = ok`.
- Runtime settings from artifact: `GET http://127.0.0.1:5014/api/settings/runtime` returned SQLite runtime and backup support.
- Final launch screenshot: `artifacts/release-final-launch.png`.
- RC1 gate launch screenshot after the latest full release check: `artifacts/rc1-release-check-launch.png`.

## Commands Run

```powershell
powershell -ExecutionPolicy Bypass -File scripts/release-check.ps1
dotnet restore Zayed.slnx --disable-build-servers -v:minimal
dotnet build Zayed.slnx --no-restore --disable-build-servers /m:1 /p:UseSharedCompilation=false /p:RunAnalyzers=false -v:minimal
powershell -ExecutionPolicy Bypass -File scripts\smoke-backup-policy.ps1
powershell -ExecutionPolicy Bypass -File scripts\smoke-backup-restore.ps1
powershell -ExecutionPolicy Bypass -File scripts\smoke-estimates-sales-orders.ps1
powershell -ExecutionPolicy Bypass -File scripts\build-release-windows.ps1 -SkipFlutterBuild
powershell -ExecutionPolicy Bypass -Command ". .\scripts\smoke-company-runtime.ps1; Get-Command Initialize-SmokeCompanyRuntime | Select-Object -ExpandProperty CommandType"
powershell -ExecutionPolicy Bypass -File scripts\smoke-time-tracking.ps1
powershell -ExecutionPolicy Bypass -File scripts\smoke-core-backend.ps1
powershell -ExecutionPolicy Bypass -File scripts\release-check.ps1
artifacts\ZayedOfflineERP-v1-win-x64\Zayed.exe
```

## Actual Results

- Latest `scripts/release-check.ps1`: PASS, exit code 0, printed `Release check completed.` after Time Tracking was added to the core backend gate.
- Final `scripts/release-check.ps1` run completed after fixing packaging to close `Zayed.exe` before rebuilding the release folder.
- Backend solution build: PASS, 0 warnings, 0 errors.
- Core backend smoke: PASS, 20 scripts passed.
- `scripts\smoke-company-runtime.ps1`: HELPER, dot-sourced successfully and exposes `Initialize-SmokeCompanyRuntime`; it is used by company-aware smoke scripts and should not run as a standalone release gate.
- `scripts\smoke-time-tracking.ps1`: PASS explicit run; created, approved, and marked a billable time entry with `2.5` total/billable hours.
- Time Tracking release gate: PASS inside `scripts\smoke-core-backend.ps1` and inside the latest `scripts\release-check.ps1`.
- Flutter analyze: PASS for release gate with `--no-fatal-warnings --no-fatal-infos`; analyzer still reports 138 warnings/info that should be cleaned after v1.
- Flutter Windows build: PASS, produced `QuickBooksFlutter/zayed/build/windows/x64/runner/Release/Zayed.exe`.
- Release package: PASS, created `artifacts/ZayedOfflineERP-v1-win-x64/`.
- Artifact launch: PASS for process startup and bundled API auto-start.
- Startup screen: PASS for no service-unavailable screen. Latest artifact launch opened directly to `Company Home` because an authenticated local session was already present.
- Dashboard visual: PASS, latest artifact screenshot shows `Company Home` loaded from `artifacts/ZayedOfflineERP-v1-win-x64/Zayed.exe`.
- `ActiveCompanyRequiredMiddleware`: PASS for startup/runtime paths; `/api/health`, `/api/settings/runtime`, `/api/companies/*`, `/api/setup/*`, `/api/auth/*`, and `/api/licenses/*` are not blocked before a company is open.

## Artifact QA

- [x] Create/open isolated QA company via artifact API.
- [x] Setup flow via artifact API.
- [x] Login via artifact API.
- [x] Previous artifact launch reached the login screen from the release folder.
- [x] Dashboard data path covered by authenticated runtime/report APIs.
- [x] Latest artifact opens visually to `Company Home` from the release folder.
- [x] Bundled API starts automatically from the release folder.
- [x] No service-unavailable screen appears on latest artifact launch.
- [x] Create customer.
- [x] Create vendor.
- [x] Create item.
- [x] Create invoice.
- [x] Receive payment.
- [x] Create sales receipt.
- [x] Create purchase order.
- [x] Receive inventory against purchase order.
- [x] Create bill from receipt.
- [x] Pay vendor.
- [x] Run Trial Balance.
- [x] Run Profit and Loss.
- [x] Create backup.
- [x] Restore backup.
- [x] Verify restore removes post-backup data and creates safety backup.
- [x] Fetch invoice print data for preview/PDF pipeline.
- [ ] Fresh visual login screen and login action still need a human pass from the release folder; latest launch reused an existing authenticated session and opened the dashboard directly.
- [ ] Visual create/open company flow still needs a human pass from the release folder.
- [ ] Visual desktop workflow still needs a human pass: create customer, create item, create invoice, save/post invoice, receive payment if supported by the UI.
- [ ] Invoice preview/PDF from the desktop UI still needs a human pass, including Arabic rendering, totals, and company info.
- [ ] Physical printer output was not tested; only invoice print-data/preview pipeline was verified by API.

Artifact QA evidence:

- QA database: `artifacts/qa/release-v1-artifact-qa.zayed`
- QA company opened and initialized.
- `qaadmin` login succeeded through the artifact API.
- Created counts after restore: 1 customer, 1 vendor, 1 item, 1 invoice, 1 sales receipt, 1 purchase order, 1 inventory receipt, 1 purchase bill, 1 vendor payment.
- Trial Balance returned 35 rows and balanced at debit `800.0` / credit `800.0`.
- Profit and Loss returned 3 sections with net profit `200.0`.
- Invoice print data returned document number `1001-000001` with one line and total `150.000`.
- Backup restore created safety backup and removed the customer created after the backup.
- Latest artifact launch after full release check:
  - `Zayed.exe` path: `artifacts/ZayedOfflineERP-v1-win-x64/Zayed.exe`
  - `Zayed.Api.exe` path: `artifacts/ZayedOfflineERP-v1-win-x64/api/Zayed.Api.exe`
  - `GET http://127.0.0.1:5014/api/health`: `status = ok`
  - Screenshot: `artifacts/rc1-release-check-launch.png`

## Backup/Restore Test

- `scripts\smoke-backup-policy.ps1`: PASS.
- `scripts\smoke-backup-restore.ps1`: PASS.
- Full restore smoke created a baseline customer/item/invoice, created a backup, changed live data, restored with safety backup, and verified:
  - restored customer balance returned to `120.0`
  - restored item quantity returned to `2.0`
  - post-backup customer was removed
  - post-backup invoice was removed
  - safety backup was created

## Remaining Blockers Before Calling It Commercial-Ready

- Fresh visual login screen and login action must be manually confirmed from `artifacts/ZayedOfflineERP-v1-win-x64/Zayed.exe`; the latest launch reused an existing session and opened the dashboard directly.
- Visual create/open company, customer/item/invoice/payment workflow must be manually confirmed from the desktop UI.
- Invoice preview/PDF and Arabic print rendering must be manually confirmed from the desktop UI.
- Physical print output was not tested; invoice print-data path passed, but a real preview/PDF/printer pass is still required.
- Flutter analyzer warnings/info remain at 138. They are not release-gating in this run, but they should be scheduled immediately after v1.

## Known Issues

- Windows build is slow during native CMake/MSBuild; successful runs took a long time even after the Flutter kernel snapshot completed.
- Old orphaned smoke/build processes can print late errors after a successful release run. Stop stale `Zayed`, `Zayed.Api`, `dotnet`, `dart`, `flutter`, `MSBuild`, `cmake`, and stray `powershell` processes before judging a new run.
- Latest explicit core smoke and full release check both exited 0, but the console still printed late orphaned messages after success: `Inventory receipt did not get a sync-ready document number.`, `Security roles should require an authentication token.`, `138 issues found.`, and `Nuget.exe not found...`. These appeared after successful completion and remain an output-cleanup issue to investigate after RC1 gating is stable.
- `release-check.ps1` now closes `Zayed.exe` before packaging; leaving the released app open can otherwise lock plugin DLLs and break release folder recreation.
- Desktop UI automation with `SendKeys` was not reliable enough to count as a real dashboard pass.

## Deferred From Offline v1

- SQL Server production mode.
- Sync.
- Payroll.
- Advanced Inventory.
- LAN/Hosted mode.

## Release Decision

Do not mark this build commercial-ready yet. The latest automated release check and artifact API QA passed, the Windows artifact exists and starts its bundled API, and the dashboard opens visually from the artifact folder without the service-unavailable screen. This is still not `Zayed Offline ERP v1 RC1` until fresh visual login, create/open company, the customer/item/invoice/payment UI workflow, and invoice preview/PDF or printer output are manually passed from the artifact folder.
