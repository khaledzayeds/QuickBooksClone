namespace QuickBooksClone.Api.Contracts.PurchaseBills;

public sealed record PurchaseBillLineDto(
    Guid Id,
    Guid ItemId,
    Guid? InventoryReceiptLineId,
    string Description,
    decimal Quantity,
    decimal UnitCost,
    decimal LineTotal);
