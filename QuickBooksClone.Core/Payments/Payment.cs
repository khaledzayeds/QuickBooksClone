using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Payments;

public sealed class Payment : SyncDocumentBase, ITenantEntity
{
    private Payment()
    {
        CompanyId = Guid.Empty;
        PaymentMethod = string.Empty;
        PaymentNumber = string.Empty;
    }

    public Payment(
        Guid customerId,
        Guid invoiceId,
        Guid depositAccountId,
        DateOnly paymentDate,
        decimal amount,
        string paymentMethod,
        string? paymentNumber = null,
        Guid? companyId = null)
    {
        if (customerId == Guid.Empty)
        {
            throw new ArgumentException("Customer is required.", nameof(customerId));
        }

        if (invoiceId == Guid.Empty)
        {
            throw new ArgumentException("Invoice is required.", nameof(invoiceId));
        }

        if (depositAccountId == Guid.Empty)
        {
            throw new ArgumentException("Deposit account is required.", nameof(depositAccountId));
        }

        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Payment amount must be greater than zero.");
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        CustomerId = customerId;
        InvoiceId = invoiceId;
        DepositAccountId = depositAccountId;
        PaymentDate = paymentDate;
        Amount = amount;
        PaymentMethod = string.IsNullOrWhiteSpace(paymentMethod) ? "Cash" : paymentMethod.Trim();
        PaymentNumber = string.IsNullOrWhiteSpace(paymentNumber) ? $"PAY-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : paymentNumber.Trim();
        Status = PaymentStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid CustomerId { get; }
    public Guid InvoiceId { get; }
    public Guid DepositAccountId { get; }
    public DateOnly PaymentDate { get; }
    public decimal Amount { get; }
    public string PaymentMethod { get; }
    public string PaymentNumber { get; }
    public PaymentStatus Status { get; private set; }
    public Guid? PostedTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }
    public Guid? ReversalTransactionId { get; private set; }
    public DateTimeOffset? VoidedAt { get; private set; }

    public void MarkPosted(Guid transactionId)
    {
        if (Status == PaymentStatus.Void)
        {
            throw new InvalidOperationException("Cannot post a void payment.");
        }

        if (PostedTransactionId is not null)
        {
            throw new InvalidOperationException("Payment is already posted.");
        }

        PostedTransactionId = transactionId;
        PostedAt = DateTimeOffset.UtcNow;
        Status = PaymentStatus.Posted;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Void(Guid? reversalTransactionId = null)
    {
        if (Status == PaymentStatus.Void)
        {
            if (ReversalTransactionId is null && reversalTransactionId is not null)
            {
                ReversalTransactionId = reversalTransactionId;
                UpdatedAt = DateTimeOffset.UtcNow;
            }

            return;
        }

        ReversalTransactionId = reversalTransactionId;
        VoidedAt = DateTimeOffset.UtcNow;
        Status = PaymentStatus.Void;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
