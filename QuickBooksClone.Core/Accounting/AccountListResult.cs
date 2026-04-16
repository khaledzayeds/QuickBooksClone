namespace QuickBooksClone.Core.Accounting;

public sealed record AccountListResult(
    IReadOnlyList<Account> Items,
    int TotalCount,
    int Page,
    int PageSize);
