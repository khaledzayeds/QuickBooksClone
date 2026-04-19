namespace QuickBooksClone.Api.Contracts.Database;

public sealed record DatabaseBackupListResponse(
    IReadOnlyList<DatabaseBackupDto> Items,
    int TotalCount);
