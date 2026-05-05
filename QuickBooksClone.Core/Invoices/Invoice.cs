using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Invoices;

public sealed class Invoice : SyncDocumentBase, ITenantEntity
{
    private readonly List<InvoiceLine> _lines = [];

    private Invoice()
    {
        CompanyId = Guid.Empty;
        InvoiceNumber = string.Empty;
    }

    public Invoice(
        Guid customerId,
        DateOnly invoiceDate,
        DateOnly dueDate,
        Guid? salesOrderId = null,
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
        SalesOrderId = salesOrderId;
        var defaultPrefix = paymentMode == InvoicePaymentMode.Cash ? "SR" : "INV";
        InvoiceNumber = string.IsNullOrWhiteSpace(invoiceNumber) ? $"{defaultPrefix}-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : invoiceNumber.Trim();
        InvoiceDate = invoiceDate;
        DueDate = dueDate;
        PaymentMode = paymentMode;
        DepositAccountId = depositAccountId;
        PaymentMethod = string.IsNullOrWhiteSpace(paymentMethod) ? null : paymentMethod.Trim();
        Status = InvoiceStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid CustomerId { get; private set; }
    public Guid? SalesOrderId { get; }
    public string InvoiceNumber { get; }
    public DateOnly InvoiceDate { get; private set; }
    public DateOnly DueDate { get; private set; }
    public InvoicePaymentMode PaymentMode { get; }
    public Guid? DepositAccountId { get; private set; }
    public string? PaymentMethod { get; private set; }
    public Guid? ReceiptPaymentId { get; private set; }
    public InvoiceStatus Status { get; private set; }
    public IReadOnlyList<InvoiceLine> Lines => _lines;
    public decimal Subtotal => _lines.Sum(line => line.GrossAmount);
    public decimal DiscountAmount => _lines.Sum(line => line.DiscountAmount);
    public decimal TaxAmount { get; private set; }
    public decimal TotalAmount => Subtotal - DiscountAmount + TaxAmount;
    public decimal PaidAmount { get; private set; }
    public decimal CreditAppliedAmount { get; private set; }
    public decimal ReturnedAmount { get; private set; }
    public decimal BalanceDue => Math.Max(0, TotalAmount - ReturnedAmount - PaidAmount - CreditAppliedAmount);
    public Guid? PostedTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }
    public Guid? ReversalTransactionId { get; private set; }
    public DateTimeOffset? VoidedAt { get; private set; }

    public void UpdateDraftHeader(Guid customerId, DateOnly invoiceDate, DateOnly dueDate, Guid? depositAccountId = null, string? paymentMethod = null)
    {
        EnsureDraftEditable();

        if (customerId == Guid.Empty)
        {
            throw new ArgumentException("Customer is required.", nameof(customerId));
        }

        if (dueDate < invoiceDate)
        {
            throw new InvalidOperationException("Due date cannot be before document date.");
        }

        CustomerId = customerId;
        InvoiceDate = invoiceDate;
        DueDate = dueDate;
        if (PaymentMode == InvoicePaymentMode.Cash)
        {
            DepositAccountId = depositAccountId;
            PaymentMethod = string.IsNullOrWhiteSpace(paymentMethod) ? null : paymentMethod.Trim();
        }

        TouchForLocalChange();
    }

    public void ReplaceDraftLines(IEnumerable<InvoiceLine> lines)
    {
        EnsureDraftEditable();

        var newLines = lines.ToList();
        if (newLines.Count == 0)
        {
            throw new InvalidOperationException("Document must have at least one line.");
        }

        _lines.Clear();
        TaxAmount = 0;
        foreach (var line in newLines)
        {
            _lines.Add(line);
            TaxAmount += line.TaxAmount;
        }

        TouchForLocalChange();
    }

    public void AddLine(InvoiceLine line)
    {
        if (Status is InvoiceStatus.Void or InvoiceStatus.Posted)
        {
            throw new InvalidOperationException("Cannot change a void or posted invoice.");
        }

        _lines.Add(line);
        TaxAmount += line.TaxAmount;
        TouchForLocalChange();
    }

    public void MarkSent()
    {
        if (Status == InvoiceStatus.Draft)
        {
            Status = InvoiceStatus.Sent;
            TouchForLocalChange();
        }
    }

    public void Void(Guid? reversalTransactionId = null)
    {
        if (Status == InvoiceStatus.Void)
        {
            if (ReversalTransactionId is null && reversalTransactionId is not null)
            {
                ReversalTransactionId = reversalTransactionId;
                TouchForLocalChange();
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
        TouchForLocalChange();
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
        TouchForLocalChange();
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
        TouchForLocalChange();
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
        TouchForLocalChange();
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
        TouchForLocalChange();
    }

    public void ApplyCredit(decimal amount)
    {
        if (Status is InvoiceStatus.Void or InvoiceStatus.Draft)
        {
            throw new InvalidOperationException("Cannot apply customer credit to a draft or void invoice.");
        }

        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Credit amount must be greater than zero.");
        }

        if (amount > BalanceDue)
        {
            throw new InvalidOperationException("Credit amount cannot exceed invoice balance.");
        }

        CreditAppliedAmount += amount;
        Status = BalanceDue == 0 ? InvoiceStatus.Paid : InvoiceStatus.PartiallyPaid;
        TouchForLocalChange();
    }

    public void ApplyReturn(decimal amount)
    {
        if (Status is InvoiceStatus.Draft or InvoiceStatus.Void)
        {
            throw new InvalidOperationException("Cannot apply a return to a draft or void invoice.");
        }

        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Return amount must be greater than zero.");
        }

        if (ReturnedAmount + amount > TotalAmount)
        {
            throw new InvalidOperationException("Return amount cannot exceed invoice total.");
        }

        ReturnedAmount += amount;
        if (ReturnedAmount == TotalAmount)
        {
            Status = InvoiceStatus.Returned;
        }
        else if (BalanceDue == 0)
        {
            Status = InvoiceStatus.Paid;
        }
        else if (PaidAmount > 0 || ReturnedAmount > 0)
        {
            Status = InvoiceStatus.PartiallyPaid;
        }
        else
        {
            Status = InvoiceStatus.Posted;
        }

        TouchForLocalChange();
    }

    public void ReverseReturn(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Return amount must be greater than zero.");
        }

        if (amount > ReturnedAmount)
        {
            throw new InvalidOperationException("Return reversal amount cannot exceed returned amount.");
        }

        ReturnedAmount -= amount;
        if (BalanceDue == 0)
        {
            Status = InvoiceStatus.Paid;
        }
        else if (PaidAmount > 0 || ReturnedAmount > 0 || CreditAppliedAmount > 0)
        {
            Status = InvoiceStatus.PartiallyPaid;
        }
        else
        {
            Status = InvoiceStatus.Posted;
        }

        TouchForLocalChange();
    }

    private void EnsureDraftEditable()
    {
        if (Status != InvoiceStatus.Draft)
        {
            throw new InvalidOperationException("Only draft documents can be edited.");
        }

        if (PostedTransactionId is not null || PaidAmount > 0 || ReceiptPaymentId is not null)
        {
            throw new InvalidOperationException("Document has accounting activity and cannot be edited as a draft.");
        }
    }
}
