namespace QuickBooksClone.Core.Items;

public sealed record ItemSearch(
    string? Search,
    bool IncludeInactive = false,
    int Page = 1,
    int PageSize = 25);
