namespace QuickBooksClone.Api.Contracts.Database;

public sealed record DatabaseRestoreAuditDto(
    string BackupFileName,
    string BackupFullPath,
    DateTimeOffset RestoredAt,
    bool CreatedSafetyBackup,
    string? SafetyBackupFileName,
    string? RequestedBy,
    string? Reason,
    string? LiveDatabasePath,
    string Provider);
