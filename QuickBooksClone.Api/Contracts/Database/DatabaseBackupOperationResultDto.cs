namespace QuickBooksClone.Api.Contracts.Database;

public sealed record DatabaseBackupOperationResultDto(
    string FileName,
    string FullPath,
    long SizeBytes,
    DateTimeOffset CreatedAt,
    bool CreatedSafetyBackup);
