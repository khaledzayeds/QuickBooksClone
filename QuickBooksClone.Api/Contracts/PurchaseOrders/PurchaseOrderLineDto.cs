namespace QuickBooksClone.Api.Contracts.PurchaseOrders;

public sealed record PurchaseOrderLineDto(
    Guid Id,
    Guid ItemId,
    string Description,
    decimal Quantity,
    decimal UnitCost,
    Guid? TaxCodeId,
    decimal TaxRatePercent,
    decimal TaxAmount,
    decimal LineTotal);
