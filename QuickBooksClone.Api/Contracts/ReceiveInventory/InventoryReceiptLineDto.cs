namespace QuickBooksClone.Api.Contracts.ReceiveInventory;

public sealed record InventoryReceiptLineDto(
    Guid Id,
    Guid ItemId,
    Guid? PurchaseOrderLineId,
    string Description,
    decimal Quantity,
    decimal UnitCost,
    decimal LineTotal);
