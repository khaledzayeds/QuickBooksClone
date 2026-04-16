namespace QuickBooksClone.Maui.Services.Accounting;

public sealed record AccountListResponse(
    IReadOnlyList<AccountDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
