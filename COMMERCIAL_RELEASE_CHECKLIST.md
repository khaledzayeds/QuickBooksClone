# Commercial Release Checklist - Zayed Offline ERP v1

Last updated: 2026-05-30 02:08 Africa/Cairo
Branch: `release/v1-zayed-offline`

## Automated Checks

- [x] Backend solution restore passed.
- [x] Backend solution build passed.
- [x] Core backend smoke passed.
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

## Commands Run

```powershell
powershell -ExecutionPolicy Bypass -File scripts/release-check.ps1
dotnet restore Zayed.slnx --disable-build-servers -v:minimal
dotnet build Zayed.slnx --no-restore --disable-build-servers /m:1 /p:UseSharedCompilation=false /p:RunAnalyzers=false -v:minimal
powershell -ExecutionPolicy Bypass -File scripts\smoke-backup-policy.ps1
powershell -ExecutionPolicy Bypass -File scripts\smoke-backup-restore.ps1
powershell -ExecutionPolicy Bypass -File scripts\smoke-estimates-sales-orders.ps1
powershell -ExecutionPolicy Bypass -File scripts\build-release-windows.ps1 -SkipFlutterBuild
```

## Actual Results

- `scripts/release-check.ps1`: PASS, exit code 0, printed `Release check completed.`
- Final `scripts/release-check.ps1` run completed after fixing packaging to close `Zayed.exe` before rebuilding the release folder.
- Backend solution build: PASS, 0 warnings, 0 errors.
- Core backend smoke: PASS, 19 scripts passed.
- Flutter analyze: PASS for release gate with `--no-fatal-warnings --no-fatal-infos`; analyzer still reports 138 warnings/info that should be cleaned after v1.
- Flutter Windows build: PASS, produced `QuickBooksFlutter/zayed/build/windows/x64/runner/Release/Zayed.exe`.
- Release package: PASS, created `artifacts/ZayedOfflineERP-v1-win-x64/`.
- Artifact launch: PASS for process startup and bundled API auto-start.
- Startup screen: PASS after increasing local backend startup timeout; app reaches the login screen instead of the old service-unavailable screen.
- `ActiveCompanyRequiredMiddleware`: PASS for startup/runtime paths; `/api/health`, `/api/settings/runtime`, `/api/companies/*`, `/api/setup/*`, `/api/auth/*`, and `/api/licenses/*` are not blocked before a company is open.

## Artifact QA

- [x] Create/open isolated QA company via artifact API.
- [x] Setup flow via artifact API.
- [x] Login via artifact API.
- [x] App opens visually to login screen from the release folder.
- [x] Dashboard data path covered by authenticated runtime/report APIs.
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
- [ ] Visual desktop login and dashboard navigation still need one human pass from the release folder.
- [ ] Physical printer output was not tested; only invoice print-data/preview pipeline was verified.

Artifact QA evidence:

- QA database: `artifacts/qa/release-v1-artifact-qa.zayed`
- QA company opened and initialized.
- `qaadmin` login succeeded through the artifact API.
- Created counts after restore: 1 customer, 1 vendor, 1 item, 1 invoice, 1 sales receipt, 1 purchase order, 1 inventory receipt, 1 purchase bill, 1 vendor payment.
- Trial Balance returned 35 rows and balanced at debit `800.0` / credit `800.0`.
- Profit and Loss returned 3 sections with net profit `200.0`.
- Invoice print data returned document number `1001-000001` with one line and total `150.000`.
- Backup restore created safety backup and removed the customer created after the backup.

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

- Visual desktop login/dashboard must be manually confirmed from `artifacts/ZayedOfflineERP-v1-win-x64/Zayed.exe`.
- Physical print output was not tested; invoice print-data path passed, but a real preview/PDF/printer pass is still required.
- Flutter analyzer warnings/info remain at 138. They are not release-gating in this run, but they should be scheduled immediately after v1.

## Known Issues

- Windows build is slow during native CMake/MSBuild; successful runs took a long time even after the Flutter kernel snapshot completed.
- Old orphaned smoke/build processes can print late errors after a successful release run. Stop stale `Zayed`, `Zayed.Api`, `dotnet`, `dart`, `flutter`, `MSBuild`, `cmake`, and stray `powershell` processes before judging a new run.
- `release-check.ps1` now closes `Zayed.exe` before packaging; leaving the released app open can otherwise lock plugin DLLs and break release folder recreation.
- Desktop UI automation with `SendKeys` was not reliable enough to count as a real dashboard pass.

## Deferred From Offline v1

- SQL Server production mode.
- Sync.
- Payroll.
- Advanced Inventory.
- LAN/Hosted mode.

## Release Decision

Do not mark this build commercial-ready yet. The automated release check and artifact API QA passed, the Windows artifact exists and starts its bundled API, but visual desktop login/dashboard and real print preview/output still need a final human pass from the artifact folder.
