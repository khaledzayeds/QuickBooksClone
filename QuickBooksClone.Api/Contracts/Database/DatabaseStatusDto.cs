namespace QuickBooksClone.Api.Contracts.Database;

public sealed record DatabaseStatusDto(
    string Provider,
    bool SupportsBackupRestore,
    string? LiveDatabasePath,
    string BackupDirectory,
    int BackupCount);
