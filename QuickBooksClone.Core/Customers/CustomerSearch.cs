namespace QuickBooksClone.Core.Customers;

public sealed record CustomerSearch(
    string? Search,
    bool IncludeInactive = false,
    int Page = 1,
    int PageSize = 25);
