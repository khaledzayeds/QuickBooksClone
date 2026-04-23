namespace QuickBooksClone.Core.SalesOrders;

public sealed record SalesOrderListResult(
    IReadOnlyList<SalesOrder> Items,
    int TotalCount,
    int Page,
    int PageSize);
