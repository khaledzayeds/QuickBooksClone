# Zayed Offline ERP

Zayed Offline ERP is a Windows desktop accounting and inventory application for the first commercial offline release. The v1 target is a local Flutter Windows client, a bundled local API, and a local SQLite company database.

## v1 Scope

- Flutter Windows desktop client: `QuickBooksFlutter/zayed`
- Local backend API: `Zayed.Api`
- Core domain: `Zayed.Core`
- Data access and SQLite persistence: `Zayed.Infrastructure`
- SQL Server migrations remain in `Zayed.SqlServerMigrations` for later validation

## Deferred For v1

SQL Server production hosting, sync, LAN/hosted deployment, payroll, and advanced inventory are not treated as production-ready in Offline v1. They can remain in code behind license gates or "coming soon" UI.

## Development

```powershell
dotnet build Zayed.slnx
cd QuickBooksFlutter/zayed
flutter pub get
flutter run -d windows
```

The Flutter app uses `http://127.0.0.1:5014` and can start the local API during desktop startup.

## Build Release

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build-release-windows.ps1
```

The release folder is created at:

```text
artifacts/ZayedOfflineERP-v1-win-x64/
```

It contains `Zayed.exe` and the bundled local API under `api/Zayed.Api.exe`.

## Release Verification

```powershell
powershell -ExecutionPolicy Bypass -File scripts/release-check.ps1
```

Use `scripts/manual-v1-qa-checklist.md` for the final customer-style QA pass before calling the release complete.
