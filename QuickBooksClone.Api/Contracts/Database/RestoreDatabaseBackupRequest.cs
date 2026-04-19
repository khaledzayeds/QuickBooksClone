namespace QuickBooksClone.Api.Contracts.Database;

public sealed record RestoreDatabaseBackupRequest(
    string FileName,
    bool CreateSafetyBackup = true);
