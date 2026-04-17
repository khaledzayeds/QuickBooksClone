namespace QuickBooksClone.Maui.Services.Accounting;

public sealed record AccountingTransactionListResponse(
    IReadOnlyList<AccountingTransactionDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
