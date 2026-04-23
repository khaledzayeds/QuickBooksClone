using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.SalesOrders;

public sealed class SalesOrder : SyncDocumentBase, ITenantEntity
{
    private readonly List<SalesOrderLine> _lines = [];

    private SalesOrder()
    {
        CompanyId = Guid.Empty;
        OrderNumber = string.Empty;
    }

    public SalesOrder(Guid customerId, DateOnly orderDate, DateOnly expectedDate, string? orderNumber = null, Guid? companyId = null)
        : this(customerId, orderDate, expectedDate, null, orderNumber, companyId)
    {
    }

    public SalesOrder(Guid customerId, DateOnly orderDate, DateOnly expectedDate, Guid? estimateId, string? orderNumber = null, Guid? companyId = null)
    {
        if (customerId == Guid.Empty)
        {
            throw new ArgumentException("Customer is required.", nameof(customerId));
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        CustomerId = customerId;
        EstimateId = estimateId;
        OrderNumber = string.IsNullOrWhiteSpace(orderNumber) ? $"SO-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : orderNumber.Trim();
        OrderDate = orderDate;
        ExpectedDate = expectedDate;
        Status = SalesOrderStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid CustomerId { get; }
    public Guid? EstimateId { get; }
    public string OrderNumber { get; }
    public DateOnly OrderDate { get; }
    public DateOnly ExpectedDate { get; private set; }
    public SalesOrderStatus Status { get; private set; }
    public IReadOnlyList<SalesOrderLine> Lines => _lines;
    public decimal TotalAmount => _lines.Sum(line => line.LineTotal);
    public DateTimeOffset? OpenedAt { get; private set; }
    public DateTimeOffset? ClosedAt { get; private set; }
    public DateTimeOffset? CancelledAt { get; private set; }

    public void AddLine(SalesOrderLine line)
    {
        if (Status is SalesOrderStatus.Closed or SalesOrderStatus.Cancelled)
        {
            throw new InvalidOperationException("Cannot change a closed or cancelled sales order.");
        }

        _lines.Add(line);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkOpen()
    {
        if (Status == SalesOrderStatus.Cancelled)
        {
            throw new InvalidOperationException("Cannot open a cancelled sales order.");
        }

        if (Status == SalesOrderStatus.Closed)
        {
            throw new InvalidOperationException("Cannot reopen a closed sales order.");
        }

        Status = SalesOrderStatus.Open;
        OpenedAt ??= DateTimeOffset.UtcNow;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Close()
    {
        if (Status == SalesOrderStatus.Cancelled)
        {
            throw new InvalidOperationException("Cannot close a cancelled sales order.");
        }

        if (Status == SalesOrderStatus.Closed)
        {
            return;
        }

        Status = SalesOrderStatus.Closed;
        ClosedAt = DateTimeOffset.UtcNow;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Cancel()
    {
        if (Status == SalesOrderStatus.Closed)
        {
            throw new InvalidOperationException("Cannot cancel a closed sales order.");
        }

        if (Status == SalesOrderStatus.Cancelled)
        {
            return;
        }

        Status = SalesOrderStatus.Cancelled;
        CancelledAt = DateTimeOffset.UtcNow;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
