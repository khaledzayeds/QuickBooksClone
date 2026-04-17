namespace QuickBooksClone.Api.Contracts.Accounting;

public sealed record AccountingTransactionListResponse(
    IReadOnlyList<AccountingTransactionDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
