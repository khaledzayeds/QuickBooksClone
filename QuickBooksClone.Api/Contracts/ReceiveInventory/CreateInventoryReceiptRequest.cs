using QuickBooksClone.Core.ReceiveInventory;

namespace QuickBooksClone.Api.Contracts.ReceiveInventory;

public sealed record CreateInventoryReceiptRequest(
    Guid VendorId,
    DateOnly ReceiptDate,
    Guid? PurchaseOrderId,
    InventoryReceiptSaveMode SaveMode,
    IReadOnlyList<CreateInventoryReceiptLineRequest> Lines);
