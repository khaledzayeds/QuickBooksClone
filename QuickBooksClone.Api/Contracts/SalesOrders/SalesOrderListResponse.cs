namespace QuickBooksClone.Api.Contracts.SalesOrders;

public sealed record SalesOrderListResponse(
    IReadOnlyList<SalesOrderDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
