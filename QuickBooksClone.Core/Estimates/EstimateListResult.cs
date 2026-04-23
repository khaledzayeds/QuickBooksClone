namespace QuickBooksClone.Core.Estimates;

public sealed record EstimateListResult(
    IReadOnlyList<Estimate> Items,
    int TotalCount,
    int Page,
    int PageSize);
