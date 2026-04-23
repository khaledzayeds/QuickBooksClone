using QuickBooksClone.Core.PurchaseOrders;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.ReceiveInventory;

namespace QuickBooksClone.Core.PurchaseWorkflow;

public interface IPurchaseWorkflowService
{
    Task<PurchaseOrderReceivingPlan?> GetReceivingPlanAsync(Guid purchaseOrderId, CancellationToken cancellationToken = default);
    Task<InventoryReceiptBillingPlan?> GetBillingPlanAsync(Guid inventoryReceiptId, CancellationToken cancellationToken = default);
}

public sealed record PurchaseOrderReceivingPlan(
    Guid PurchaseOrderId,
    string OrderNumber,
    Guid VendorId,
    PurchaseOrderStatus Status,
    bool CanReceive,
    bool IsFullyReceived,
    decimal TotalOrderedQuantity,
    decimal TotalReceivedQuantity,
    decimal TotalRemainingQuantity,
    IReadOnlyList<PurchaseOrderReceivingPlanLine> Lines,
    IReadOnlyList<LinkedInventoryReceiptReference> LinkedReceipts);

public sealed record PurchaseOrderReceivingPlanLine(
    Guid PurchaseOrderLineId,
    Guid ItemId,
    string Description,
    decimal OrderedQuantity,
    decimal ReceivedQuantity,
    decimal RemainingQuantity,
    decimal SuggestedReceiveQuantity,
    decimal UnitCost);

public sealed record LinkedInventoryReceiptReference(
    Guid Id,
    string ReceiptNumber,
    DateOnly ReceiptDate,
    InventoryReceiptStatus Status);

public sealed record InventoryReceiptBillingPlan(
    Guid InventoryReceiptId,
    string ReceiptNumber,
    Guid VendorId,
    Guid? PurchaseOrderId,
    InventoryReceiptStatus Status,
    bool CanBill,
    bool IsFullyBilled,
    decimal TotalReceivedQuantity,
    decimal TotalBilledQuantity,
    decimal TotalRemainingQuantity,
    IReadOnlyList<InventoryReceiptBillingPlanLine> Lines,
    IReadOnlyList<LinkedPurchaseBillReference> LinkedBills);

public sealed record InventoryReceiptBillingPlanLine(
    Guid InventoryReceiptLineId,
    Guid ItemId,
    Guid? PurchaseOrderLineId,
    string Description,
    decimal ReceivedQuantity,
    decimal BilledQuantity,
    decimal RemainingQuantity,
    decimal SuggestedBillQuantity,
    decimal UnitCost);

public sealed record LinkedPurchaseBillReference(
    Guid Id,
    string BillNumber,
    DateOnly BillDate,
    PurchaseBillStatus Status);
