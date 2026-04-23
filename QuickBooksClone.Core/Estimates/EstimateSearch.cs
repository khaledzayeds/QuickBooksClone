namespace QuickBooksClone.Core.Estimates;

public sealed record EstimateSearch(
    string? Search,
    Guid? CustomerId,
    bool IncludeClosed,
    bool IncludeCancelled,
    int Page,
    int PageSize);
