namespace QuickBooksClone.Api.Contracts.Database;

public sealed record DatabaseBackupDto(
    string FileName,
    string FullPath,
    long SizeBytes,
    DateTimeOffset CreatedAt,
    string BackupKind,
    string? Label,
    string? RequestedBy,
    string? Reason);
