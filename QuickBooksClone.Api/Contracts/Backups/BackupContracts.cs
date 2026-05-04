namespace QuickBooksClone.Api.Contracts.Backups;

public sealed record BackupFileDto(
    string FileName,
    long SizeBytes,
    DateTimeOffset CreatedAt,
    string BackupKind,
    string? Label,
    string? RequestedBy,
    string? Reason);

public sealed record DatabaseMaintenanceSettingsDto(
    bool AutoBackupEnabled,
    string ScheduleMode,
    int RunAtHourLocal,
    int RetentionCount,
    bool CreateSafetyBackupBeforeRestore,
    string? PreferredLabelPrefix,
    DateTimeOffset? UpdatedAt,
    string? UpdatedBy);

public sealed record UpdateDatabaseMaintenanceSettingsRequest(
    bool AutoBackupEnabled,
    string ScheduleMode,
    int RunAtHourLocal,
    int RetentionCount,
    bool CreateSafetyBackupBeforeRestore,
    string? PreferredLabelPrefix);

public sealed record CreateBackupRequest(
    string? Label,
    string? Reason);

public sealed record ImportBackupRequest(
    string? Label,
    string? Reason);

public sealed record RestoreBackupRequest(
    string FileName,
    bool CreateSafetyBackup,
    string? Reason);

public sealed record RestoreAuditDto(
    string BackupFileName,
    DateTimeOffset RestoredAt,
    bool CreatedSafetyBackup,
    string? SafetyBackupFileName,
    string? RequestedBy,
    string? Reason,
    string Provider);

public sealed record RestoreBackupResponse(
    BackupFileDto RestoredBackup,
    BackupFileDto? SafetyBackup,
    RestoreAuditDto RestoreAudit);
