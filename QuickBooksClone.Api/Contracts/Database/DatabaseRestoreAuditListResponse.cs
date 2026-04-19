namespace QuickBooksClone.Api.Contracts.Database;

public sealed record DatabaseRestoreAuditListResponse(
    IReadOnlyList<DatabaseRestoreAuditDto> Items,
    int TotalCount);
