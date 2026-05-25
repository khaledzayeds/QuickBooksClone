namespace Zayed.Core.PurchaseOrders;

public sealed record PurchaseOrderListResult(
    IReadOnlyList<PurchaseOrder> Items,
    int TotalCount,
    int Page,
    int PageSize);
