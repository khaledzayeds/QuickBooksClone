namespace QuickBooksClone.Core.Vendors;

public sealed record VendorSearch(
    string? Search,
    bool IncludeInactive,
    int Page,
    int PageSize);
