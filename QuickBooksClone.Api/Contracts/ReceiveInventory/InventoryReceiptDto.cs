using QuickBooksClone.Core.ReceiveInventory;

namespace QuickBooksClone.Api.Contracts.ReceiveInventory;

public sealed record InventoryReceiptDto(
    Guid Id,
    string ReceiptNumber,
    Guid VendorId,
    string? VendorName,
    Guid? PurchaseOrderId,
    string? PurchaseOrderNumber,
    DateOnly ReceiptDate,
    InventoryReceiptStatus Status,
    decimal TotalAmount,
    Guid? PostedTransactionId,
    DateTimeOffset? PostedAt,
    Guid? ReversalTransactionId,
    DateTimeOffset? VoidedAt,
    IReadOnlyList<InventoryReceiptLineDto> Lines);
