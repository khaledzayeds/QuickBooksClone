namespace QuickBooksClone.Core.SalesOrders;

public sealed record SalesOrderSearch(
    string? Search,
    Guid? CustomerId,
    bool IncludeClosed,
    bool IncludeCancelled,
    int Page,
    int PageSize);
