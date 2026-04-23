using QuickBooksClone.Core.PurchaseOrders;
using QuickBooksClone.Core.ReceiveInventory;

namespace QuickBooksClone.Api.Contracts.PurchaseWorkflow;

public sealed record PurchaseOrderReceivingPlanDto(
    Guid PurchaseOrderId,
    string OrderNumber,
    Guid VendorId,
    string? VendorName,
    PurchaseOrderStatus Status,
    bool CanReceive,
    bool IsFullyReceived,
    decimal TotalOrderedQuantity,
    decimal TotalReceivedQuantity,
    decimal TotalRemainingQuantity,
    IReadOnlyList<PurchaseOrderReceivingPlanLineDto> Lines,
    IReadOnlyList<LinkedInventoryReceiptReferenceDto> LinkedReceipts);

public sealed record PurchaseOrderReceivingPlanLineDto(
    Guid PurchaseOrderLineId,
    Guid ItemId,
    string Description,
    decimal OrderedQuantity,
    decimal ReceivedQuantity,
    decimal RemainingQuantity,
    decimal SuggestedReceiveQuantity,
    decimal UnitCost);

public sealed record LinkedInventoryReceiptReferenceDto(
    Guid Id,
    string ReceiptNumber,
    DateOnly ReceiptDate,
    InventoryReceiptStatus Status);
