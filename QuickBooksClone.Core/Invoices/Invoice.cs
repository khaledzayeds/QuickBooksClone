using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Invoices;

public sealed class Invoice : EntityBase, ITenantEntity
{
    private readonly List<InvoiceLine> _lines = [];

    public Invoice(
        Guid customerId,
        DateOnly invoiceDate,
        DateOnly dueDate,
        string? invoiceNumber = null,
        Guid? companyId = null,
        InvoicePaymentMode paymentMode = InvoicePaymentMode.Credit,
        Guid? depositAccountId = null,
        string? paymentMethod = null)
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
        PaymentMode = paymentMode;
        DepositAccountId = depositAccountId;
        PaymentMethod = string.IsNullOrWhiteSpace(paymentMethod) ? null : paymentMethod.Trim();
        Status = InvoiceStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid CustomerId { get; }
    public string InvoiceNumber { get; }
    public DateOnly InvoiceDate { get; }
    public DateOnly DueDate { get; }
    public InvoicePaymentMode PaymentMode { get; }
    public Guid? DepositAccountId { get; }
    public string? PaymentMethod { get; }
    public Guid? ReceiptPaymentId { get; private set; }
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
    public Guid? ReversalTransactionId { get; private set; }
    public DateTimeOffset? VoidedAt { get; private set; }

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

    public void Void(Guid? reversalTransactionId = null)
    {
        if (Status == InvoiceStatus.Void)
        {
            if (ReversalTransactionId is null && reversalTransactionId is not null)
            {
                ReversalTransactionId = reversalTransactionId;
                UpdatedAt = DateTimeOffset.UtcNow;
            }

            return;
        }

        if (PaidAmount > 0)
        {
            throw new InvalidOperationException("Cannot void an invoice with applied payments.");
        }

        ReversalTransactionId = reversalTransactionId;
        VoidedAt = DateTimeOffset.UtcNow;
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

    public void ApplyPayment(decimal amount)
    {
        if (Status is InvoiceStatus.Void or InvoiceStatus.Draft)
        {
            throw new InvalidOperationException("Cannot apply a payment to a draft or void invoice.");
        }

        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Payment amount must be greater than zero.");
        }

        if (amount > BalanceDue)
        {
            throw new InvalidOperationException("Payment amount cannot exceed invoice balance.");
        }

        PaidAmount += amount;
        Status = BalanceDue == 0 ? InvoiceStatus.Paid : InvoiceStatus.PartiallyPaid;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void LinkReceiptPayment(Guid paymentId)
    {
        if (paymentId == Guid.Empty)
        {
            throw new ArgumentException("Payment is required.", nameof(paymentId));
        }

        if (ReceiptPaymentId == paymentId)
        {
            return;
        }

        if (ReceiptPaymentId is not null)
        {
            throw new InvalidOperationException("Invoice already has a linked receipt payment.");
        }

        ReceiptPaymentId = paymentId;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ReversePayment(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Payment amount must be greater than zero.");
        }

        if (amount > PaidAmount)
        {
            throw new InvalidOperationException("Payment reversal amount cannot exceed paid amount.");
        }

        PaidAmount -= amount;
        Status = PaidAmount == 0 ? InvoiceStatus.Posted : InvoiceStatus.PartiallyPaid;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
