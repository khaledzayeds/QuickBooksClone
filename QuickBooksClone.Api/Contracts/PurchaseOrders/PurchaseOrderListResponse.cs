namespace QuickBooksClone.Api.Contracts.PurchaseOrders;

public sealed record PurchaseOrderListResponse(
    IReadOnlyList<PurchaseOrderDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
