namespace QuickBooksClone.Core.Accounting;

public sealed record AccountSearch(
    string? Search,
    AccountType? AccountType = null,
    bool IncludeInactive = false,
    int Page = 1,
    int PageSize = 100);
