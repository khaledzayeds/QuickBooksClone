using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.PurchaseOrders;
using QuickBooksClone.Core.PurchaseWorkflow;
using QuickBooksClone.Core.ReceiveInventory;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Infrastructure.PurchaseWorkflow;

public sealed class PurchaseWorkflowService : IPurchaseWorkflowService
{
    private readonly QuickBooksCloneDbContext _db;
    private readonly IInventoryReceiptRepository _receipts;
    private readonly IPurchaseBillRepository _bills;
    private readonly IPurchaseOrderRepository _orders;

    public PurchaseWorkflowService(
        QuickBooksCloneDbContext db,
        IInventoryReceiptRepository receipts,
        IPurchaseBillRepository bills,
        IPurchaseOrderRepository orders)
    {
        _db = db;
        _receipts = receipts;
        _bills = bills;
        _orders = orders;
    }

    public async Task<PurchaseOrderReceivingPlan?> GetReceivingPlanAsync(Guid purchaseOrderId, CancellationToken cancellationToken = default)
    {
        var order = await _orders.GetByIdAsync(purchaseOrderId, cancellationToken);
        if (order is null)
        {
            return null;
        }

        var orderLineIds = order.Lines.Select(line => line.Id).ToList();
        var receivedByLine = await _receipts.GetReceivedQuantitiesByPurchaseOrderLineIdsAsync(orderLineIds, cancellationToken);
        var linkedReceipts = await _db.InventoryReceipts
            .AsNoTracking()
            .Where(receipt => receipt.PurchaseOrderId == order.Id && receipt.Status != InventoryReceiptStatus.Void)
            .OrderByDescending(receipt => receipt.ReceiptDate)
            .ThenByDescending(receipt => receipt.ReceiptNumber)
            .Select(receipt => new LinkedInventoryReceiptReference(
                receipt.Id,
                receipt.ReceiptNumber,
                receipt.ReceiptDate,
                receipt.Status))
            .ToListAsync(cancellationToken);

        var lines = order.Lines.Select(line =>
        {
            var received = receivedByLine.GetValueOrDefault(line.Id);
            var remaining = Math.Max(0m, line.Quantity - received);
            return new PurchaseOrderReceivingPlanLine(
                line.Id,
                line.ItemId,
                line.Description,
                line.Quantity,
                received,
                remaining,
                remaining,
                line.UnitCost);
        }).ToList();

        var totalOrdered = lines.Sum(line => line.OrderedQuantity);
        var totalReceived = lines.Sum(line => line.ReceivedQuantity);
        var totalRemaining = lines.Sum(line => line.RemainingQuantity);

        return new PurchaseOrderReceivingPlan(
            order.Id,
            order.OrderNumber,
            order.VendorId,
            order.Status,
            order.Status == PurchaseOrderStatus.Open && totalRemaining > 0m,
            totalRemaining == 0m,
            totalOrdered,
            totalReceived,
            totalRemaining,
            lines,
            linkedReceipts);
    }

    public async Task<InventoryReceiptBillingPlan?> GetBillingPlanAsync(Guid inventoryReceiptId, CancellationToken cancellationToken = default)
    {
        var receipt = await _receipts.GetByIdAsync(inventoryReceiptId, cancellationToken);
        if (receipt is null)
        {
            return null;
        }

        var receiptLineIds = receipt.Lines.Select(line => line.Id).ToList();
        var billedByLine = await _bills.GetBilledQuantitiesByInventoryReceiptLineIdsAsync(receiptLineIds, cancellationToken);
        var linkedBills = await _db.PurchaseBills
            .AsNoTracking()
            .Where(bill => bill.InventoryReceiptId == receipt.Id && bill.Status != PurchaseBillStatus.Void)
            .OrderByDescending(bill => bill.BillDate)
            .ThenByDescending(bill => bill.BillNumber)
            .Select(bill => new LinkedPurchaseBillReference(
                bill.Id,
                bill.BillNumber,
                bill.BillDate,
                bill.Status))
            .ToListAsync(cancellationToken);

        var lines = receipt.Lines.Select(line =>
        {
            var billed = billedByLine.GetValueOrDefault(line.Id);
            var remaining = Math.Max(0m, line.Quantity - billed);
            return new InventoryReceiptBillingPlanLine(
                line.Id,
                line.ItemId,
                line.PurchaseOrderLineId,
                line.Description,
                line.Quantity,
                billed,
                remaining,
                remaining,
                line.UnitCost);
        }).ToList();

        var totalReceived = lines.Sum(line => line.ReceivedQuantity);
        var totalBilled = lines.Sum(line => line.BilledQuantity);
        var totalRemaining = lines.Sum(line => line.RemainingQuantity);

        return new InventoryReceiptBillingPlan(
            receipt.Id,
            receipt.ReceiptNumber,
            receipt.VendorId,
            receipt.PurchaseOrderId,
            receipt.Status,
            receipt.Status == InventoryReceiptStatus.Posted && totalRemaining > 0m,
            totalRemaining == 0m,
            totalReceived,
            totalBilled,
            totalRemaining,
            lines,
            linkedBills);
    }
}
