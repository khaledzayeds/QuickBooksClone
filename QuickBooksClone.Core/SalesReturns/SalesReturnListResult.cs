namespace QuickBooksClone.Core.SalesReturns;

public sealed record SalesReturnListResult(
    IReadOnlyList<SalesReturn> Items,
    int TotalCount,
    int Page,
    int PageSize);
