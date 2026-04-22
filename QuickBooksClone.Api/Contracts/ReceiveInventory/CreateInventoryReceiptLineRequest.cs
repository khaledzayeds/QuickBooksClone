namespace QuickBooksClone.Api.Contracts.ReceiveInventory;

public sealed record CreateInventoryReceiptLineRequest(
    Guid ItemId,
    decimal Quantity,
    decimal UnitCost,
    string? Description,
    Guid? PurchaseOrderLineId);
