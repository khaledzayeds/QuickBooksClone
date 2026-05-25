using Zayed.Core.ReceiveInventory;

namespace Zayed.Api.Contracts.ReceiveInventory;

public sealed record CreateInventoryReceiptRequest(
    Guid VendorId,
    DateOnly ReceiptDate,
    Guid? PurchaseOrderId,
    InventoryReceiptSaveMode SaveMode,
    IReadOnlyList<CreateInventoryReceiptLineRequest> Lines);
