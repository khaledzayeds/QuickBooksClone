namespace QuickBooksClone.Infrastructure.Persistence;

public sealed record DatabaseBackupFile(
    string FileName,
    string FullPath,
    long SizeBytes,
    DateTimeOffset CreatedAt,
    string BackupKind,
    string? Label,
    string? RequestedBy,
    string? Reason);

public sealed record DatabaseStatus(
    string Provider,
    bool SupportsBackupRestore,
    string? LiveDatabasePath,
    string BackupDirectory,
    int BackupCount);

public sealed record RestoreDatabaseBackupResult(
    DatabaseBackupFile RestoredBackup,
    DatabaseBackupFile? SafetyBackup,
    DatabaseRestoreAudit RestoreAudit);

public sealed record DatabaseMaintenanceSettings(
    bool AutoBackupEnabled,
    string ScheduleMode,
    int RunAtHourLocal,
    int RetentionCount,
    bool CreateSafetyBackupBeforeRestore,
    string? PreferredLabelPrefix,
    DateTimeOffset? UpdatedAt,
    string? UpdatedBy);

public sealed record DatabaseRestoreAudit(
    string BackupFileName,
    string BackupFullPath,
    DateTimeOffset RestoredAt,
    bool CreatedSafetyBackup,
    string? SafetyBackupFileName,
    string? RequestedBy,
    string? Reason,
    string? LiveDatabasePath,
    string Provider);
