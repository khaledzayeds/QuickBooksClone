namespace QuickBooksClone.Infrastructure.Persistence;

public sealed record DatabaseBackupFile(
    string FileName,
    string FullPath,
    long SizeBytes,
    DateTimeOffset CreatedAt);

public sealed record DatabaseStatus(
    string Provider,
    bool SupportsBackupRestore,
    string? LiveDatabasePath,
    string BackupDirectory,
    int BackupCount);

public sealed record RestoreDatabaseBackupResult(
    DatabaseBackupFile RestoredBackup,
    DatabaseBackupFile? SafetyBackup);
