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
