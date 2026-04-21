using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.SalesReturns;

public sealed class SalesReturn : SyncDocumentBase, ITenantEntity
{
    private readonly List<SalesReturnLine> _lines = [];

    private SalesReturn()
    {
        CompanyId = Guid.Empty;
        ReturnNumber = string.Empty;
    }

    public SalesReturn(Guid invoiceId, Guid customerId, DateOnly returnDate, string? returnNumber = null, Guid? companyId = null)
    {
        if (invoiceId == Guid.Empty)
        {
            throw new ArgumentException("Invoice is required.", nameof(invoiceId));
        }

        if (customerId == Guid.Empty)
        {
            throw new ArgumentException("Customer is required.", nameof(customerId));
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        InvoiceId = invoiceId;
        CustomerId = customerId;
        ReturnDate = returnDate;
        ReturnNumber = string.IsNullOrWhiteSpace(returnNumber) ? $"SR-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : returnNumber.Trim();
        Status = SalesReturnStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid InvoiceId { get; }
    public Guid CustomerId { get; }
    public DateOnly ReturnDate { get; }
    public string ReturnNumber { get; }
    public SalesReturnStatus Status { get; private set; }
    public IReadOnlyList<SalesReturnLine> Lines => _lines;
    public decimal TotalAmount => _lines.Sum(line => line.LineTotal);
    public Guid? PostedTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }

    public void AddLine(SalesReturnLine line)
    {
        if (Status != SalesReturnStatus.Draft)
        {
            throw new InvalidOperationException("Cannot change a posted or void sales return.");
        }

        _lines.Add(line);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkPosted(Guid transactionId)
    {
        if (Status == SalesReturnStatus.Void)
        {
            throw new InvalidOperationException("Cannot post a void sales return.");
        }

        if (PostedTransactionId is not null)
        {
            throw new InvalidOperationException("Sales return is already posted.");
        }

        PostedTransactionId = transactionId;
        PostedAt = DateTimeOffset.UtcNow;
        Status = SalesReturnStatus.Posted;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
