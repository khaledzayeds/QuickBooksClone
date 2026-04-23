using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.ReceiveInventory;

namespace QuickBooksClone.Api.Contracts.PurchaseWorkflow;

public sealed record InventoryReceiptBillingPlanDto(
    Guid InventoryReceiptId,
    string ReceiptNumber,
    Guid VendorId,
    string? VendorName,
    Guid? PurchaseOrderId,
    string? PurchaseOrderNumber,
    InventoryReceiptStatus Status,
    bool CanBill,
    bool IsFullyBilled,
    decimal TotalReceivedQuantity,
    decimal TotalBilledQuantity,
    decimal TotalRemainingQuantity,
    IReadOnlyList<InventoryReceiptBillingPlanLineDto> Lines,
    IReadOnlyList<LinkedPurchaseBillReferenceDto> LinkedBills);

public sealed record InventoryReceiptBillingPlanLineDto(
    Guid InventoryReceiptLineId,
    Guid ItemId,
    Guid? PurchaseOrderLineId,
    string Description,
    decimal ReceivedQuantity,
    decimal BilledQuantity,
    decimal RemainingQuantity,
    decimal SuggestedBillQuantity,
    decimal UnitCost);

public sealed record LinkedPurchaseBillReferenceDto(
    Guid Id,
    string BillNumber,
    DateOnly BillDate,
    PurchaseBillStatus Status);
