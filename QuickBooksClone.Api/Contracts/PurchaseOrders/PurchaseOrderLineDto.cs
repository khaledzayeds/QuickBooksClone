namespace QuickBooksClone.Api.Contracts.PurchaseOrders;

public sealed record PurchaseOrderLineDto(
    Guid Id,
    Guid ItemId,
    string Description,
    decimal Quantity,
    decimal UnitCost,
    decimal LineTotal);
