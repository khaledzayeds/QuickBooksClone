namespace QuickBooksClone.Api.Contracts.Database;

public sealed record DatabaseBackupOperationResultDto(
    string FileName,
    string FullPath,
    long SizeBytes,
    DateTimeOffset CreatedAt,
    bool CreatedSafetyBackup,
    string BackupKind,
    string? Label,
    string? RequestedBy,
    string? Reason,
    string? SafetyBackupFileName,
    DateTimeOffset? RestoredAt);
