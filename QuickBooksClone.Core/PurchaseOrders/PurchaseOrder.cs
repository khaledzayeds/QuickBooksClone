using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.PurchaseOrders;

public sealed class PurchaseOrder : SyncDocumentBase, ITenantEntity
{
    private readonly List<PurchaseOrderLine> _lines = [];

    private PurchaseOrder()
    {
        CompanyId = Guid.Empty;
        OrderNumber = string.Empty;
    }

    public PurchaseOrder(Guid vendorId, DateOnly orderDate, DateOnly expectedDate, string? orderNumber = null, Guid? companyId = null)
    {
        if (vendorId == Guid.Empty)
        {
            throw new ArgumentException("Vendor is required.", nameof(vendorId));
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        VendorId = vendorId;
        OrderNumber = string.IsNullOrWhiteSpace(orderNumber) ? $"PO-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : orderNumber.Trim();
        OrderDate = orderDate;
        ExpectedDate = expectedDate;
        Status = PurchaseOrderStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid VendorId { get; }
    public string OrderNumber { get; }
    public DateOnly OrderDate { get; }
    public DateOnly ExpectedDate { get; private set; }
    public PurchaseOrderStatus Status { get; private set; }
    public IReadOnlyList<PurchaseOrderLine> Lines => _lines;
    public decimal Subtotal => _lines.Sum(line => line.LineTotal);
    public decimal TaxAmount => _lines.Sum(line => line.TaxAmount);
    public decimal TotalAmount => Subtotal + TaxAmount;
    public DateTimeOffset? OpenedAt { get; private set; }
    public DateTimeOffset? ClosedAt { get; private set; }
    public DateTimeOffset? CancelledAt { get; private set; }

    public void AddLine(PurchaseOrderLine line)
    {
        if (Status is PurchaseOrderStatus.Closed or PurchaseOrderStatus.Cancelled)
        {
            throw new InvalidOperationException("Cannot change a closed or cancelled purchase order.");
        }

        _lines.Add(line);
        TouchForLocalChange();
    }

    public void MarkOpen()
    {
        if (Status == PurchaseOrderStatus.Cancelled)
        {
            throw new InvalidOperationException("Cannot open a cancelled purchase order.");
        }

        if (Status == PurchaseOrderStatus.Closed)
        {
            throw new InvalidOperationException("Cannot reopen a closed purchase order.");
        }

        Status = PurchaseOrderStatus.Open;
        OpenedAt ??= DateTimeOffset.UtcNow;
        TouchForLocalChange();
    }

    public void Close()
    {
        if (Status == PurchaseOrderStatus.Cancelled)
        {
            throw new InvalidOperationException("Cannot close a cancelled purchase order.");
        }

        if (Status == PurchaseOrderStatus.Closed)
        {
            return;
        }

        Status = PurchaseOrderStatus.Closed;
        ClosedAt = DateTimeOffset.UtcNow;
        TouchForLocalChange();
    }

    public void Cancel()
    {
        if (Status == PurchaseOrderStatus.Closed)
        {
            throw new InvalidOperationException("Cannot cancel a closed purchase order.");
        }

        if (Status == PurchaseOrderStatus.Cancelled)
        {
            return;
        }

        Status = PurchaseOrderStatus.Cancelled;
        CancelledAt = DateTimeOffset.UtcNow;
        TouchForLocalChange();
    }
}
