using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.CustomerCredits;

public sealed class CustomerCreditActivity : EntityBase, ITenantEntity
{
    public CustomerCreditActivity(
        Guid customerId,
        DateOnly activityDate,
        decimal amount,
        CustomerCreditAction action,
        Guid? invoiceId = null,
        Guid? refundAccountId = null,
        string? paymentMethod = null,
        string? referenceNumber = null,
        Guid? companyId = null)
    {
        if (customerId == Guid.Empty)
        {
            throw new ArgumentException("Customer is required.", nameof(customerId));
        }

        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Amount must be greater than zero.");
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        CustomerId = customerId;
        ActivityDate = activityDate;
        Amount = amount;
        Action = action;
        InvoiceId = invoiceId;
        RefundAccountId = refundAccountId;
        PaymentMethod = string.IsNullOrWhiteSpace(paymentMethod) ? null : paymentMethod.Trim();
        ReferenceNumber = string.IsNullOrWhiteSpace(referenceNumber) ? $"CCR-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : referenceNumber.Trim();
        Status = CustomerCreditStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid CustomerId { get; }
    public DateOnly ActivityDate { get; }
    public decimal Amount { get; }
    public CustomerCreditAction Action { get; }
    public Guid? InvoiceId { get; }
    public Guid? RefundAccountId { get; }
    public string? PaymentMethod { get; }
    public string ReferenceNumber { get; }
    public CustomerCreditStatus Status { get; private set; }
    public Guid? PostedTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }

    public void MarkPosted(Guid? transactionId = null)
    {
        if (Status == CustomerCreditStatus.Void)
        {
            throw new InvalidOperationException("Cannot post a void customer credit activity.");
        }

        if (Status == CustomerCreditStatus.Posted)
        {
            return;
        }

        PostedTransactionId = transactionId;
        PostedAt = DateTimeOffset.UtcNow;
        Status = CustomerCreditStatus.Posted;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
