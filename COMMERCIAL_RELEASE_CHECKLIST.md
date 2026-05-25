# Commercial Release Checklist - Zayed Offline ERP v1

## Automated Checks

- [ ] Backend solution build passed
- [ ] Core backend smoke passed
- [ ] Flutter `pub get` passed
- [ ] Flutter analyze passed
- [ ] Flutter Windows build passed
- [ ] Windows release folder created
- [ ] Release folder contains `Zayed.exe`
- [ ] Release folder contains `api/Zayed.Api.exe`

## Manual QA

- [ ] Start app from release folder
- [ ] Bundled API starts automatically
- [ ] Create company tested
- [ ] Open existing company tested
- [ ] Setup wizard tested
- [ ] Admin login/password behavior tested
- [ ] Invoice/payment workflow tested
- [ ] Sales receipt workflow tested
- [ ] Purchase/receive/bill/payment workflow tested
- [ ] Backup/restore tested with safety backup
- [ ] Reports tested
- [ ] Print invoice tested
- [ ] Print sales receipt tested
- [ ] Arabic tested
- [ ] English tested
- [ ] License lock/activation behavior tested
- [ ] No developer playground screens visible in production navigation

## Current Notes

- Production `appsettings.json` does not ship with an active demo license.
- Development demo license lives only in development configuration.
- SQL Server, sync, payroll, hosted/LAN modes, and advanced inventory are deferred for Offline v1.
- Do not call this build commercial-ready until every automated and manual item above is checked.

## Latest Automated Attempt

- `dotnet build Zayed.slnx --no-restore --disable-build-servers /m:1 /p:UseSharedCompilation=false /p:RunAnalyzers=false -v:minimal` timed out locally after 7 minutes with no compiler output.
- `dotnet build Zayed.Api\Zayed.Api.csproj --no-restore --disable-build-servers /m:1 /p:UseSharedCompilation=false /p:RunAnalyzers=false -v:minimal` timed out locally after 6 minutes with no compiler output.
- `flutter pub get` in `QuickBooksFlutter/zayed` timed out locally after 3 minutes.
- Hung `dotnet`, `dart`, and `flutter` processes were stopped after the timeout.
- Earlier in this release work, the API build passed after `dotnet build-server shutdown`; rerun from a clean terminal before marking automated checks complete.
