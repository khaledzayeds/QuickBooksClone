using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Invoices;

public sealed class Invoice : EntityBase, ITenantEntity
{
    private readonly List<InvoiceLine> _lines = [];

    public Invoice(Guid customerId, DateOnly invoiceDate, DateOnly dueDate, string? invoiceNumber = null, Guid? companyId = null)
    {
        if (customerId == Guid.Empty)
        {
            throw new ArgumentException("Customer is required.", nameof(customerId));
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        CustomerId = customerId;
        InvoiceNumber = string.IsNullOrWhiteSpace(invoiceNumber) ? $"INV-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : invoiceNumber.Trim();
        InvoiceDate = invoiceDate;
        DueDate = dueDate;
        Status = InvoiceStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid CustomerId { get; }
    public string InvoiceNumber { get; }
    public DateOnly InvoiceDate { get; }
    public DateOnly DueDate { get; }
    public InvoiceStatus Status { get; private set; }
    public IReadOnlyList<InvoiceLine> Lines => _lines;
    public decimal Subtotal => _lines.Sum(line => line.GrossAmount);
    public decimal DiscountAmount => _lines.Sum(line => line.DiscountAmount);
    public decimal TaxAmount { get; private set; }
    public decimal TotalAmount => Subtotal - DiscountAmount + TaxAmount;
    public decimal PaidAmount { get; private set; }
    public decimal BalanceDue => TotalAmount - PaidAmount;
    public Guid? PostedTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }

    public void AddLine(InvoiceLine line)
    {
        if (Status is InvoiceStatus.Void or InvoiceStatus.Posted)
        {
            throw new InvalidOperationException("Cannot change a void or posted invoice.");
        }

        _lines.Add(line);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkSent()
    {
        if (Status == InvoiceStatus.Draft)
        {
            Status = InvoiceStatus.Sent;
            UpdatedAt = DateTimeOffset.UtcNow;
        }
    }

    public void Void()
    {
        Status = InvoiceStatus.Void;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkPosted(Guid transactionId)
    {
        if (Status == InvoiceStatus.Void)
        {
            throw new InvalidOperationException("Cannot post a void invoice.");
        }

        if (PostedTransactionId is not null)
        {
            throw new InvalidOperationException("Invoice is already posted.");
        }

        PostedTransactionId = transactionId;
        PostedAt = DateTimeOffset.UtcNow;
        Status = InvoiceStatus.Posted;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
