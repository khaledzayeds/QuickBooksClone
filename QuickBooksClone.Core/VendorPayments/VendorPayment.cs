using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.VendorPayments;

public sealed class VendorPayment : EntityBase, ITenantEntity
{
    public VendorPayment(
        Guid vendorId,
        Guid purchaseBillId,
        Guid paymentAccountId,
        DateOnly paymentDate,
        decimal amount,
        string paymentMethod,
        string? paymentNumber = null,
        Guid? companyId = null)
    {
        if (vendorId == Guid.Empty)
        {
            throw new ArgumentException("Vendor is required.", nameof(vendorId));
        }

        if (purchaseBillId == Guid.Empty)
        {
            throw new ArgumentException("Purchase bill is required.", nameof(purchaseBillId));
        }

        if (paymentAccountId == Guid.Empty)
        {
            throw new ArgumentException("Payment account is required.", nameof(paymentAccountId));
        }

        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Payment amount must be greater than zero.");
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        VendorId = vendorId;
        PurchaseBillId = purchaseBillId;
        PaymentAccountId = paymentAccountId;
        PaymentDate = paymentDate;
        Amount = amount;
        PaymentMethod = string.IsNullOrWhiteSpace(paymentMethod) ? "Cash" : paymentMethod.Trim();
        PaymentNumber = string.IsNullOrWhiteSpace(paymentNumber) ? $"VPAY-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : paymentNumber.Trim();
        Status = VendorPaymentStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid VendorId { get; }
    public Guid PurchaseBillId { get; }
    public Guid PaymentAccountId { get; }
    public DateOnly PaymentDate { get; }
    public decimal Amount { get; }
    public string PaymentMethod { get; }
    public string PaymentNumber { get; }
    public VendorPaymentStatus Status { get; private set; }
    public Guid? PostedTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }
    public Guid? ReversalTransactionId { get; private set; }
    public DateTimeOffset? VoidedAt { get; private set; }

    public void MarkPosted(Guid transactionId)
    {
        if (Status == VendorPaymentStatus.Void)
        {
            throw new InvalidOperationException("Cannot post a void vendor payment.");
        }

        if (PostedTransactionId is not null)
        {
            throw new InvalidOperationException("Vendor payment is already posted.");
        }

        PostedTransactionId = transactionId;
        PostedAt = DateTimeOffset.UtcNow;
        Status = VendorPaymentStatus.Posted;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
