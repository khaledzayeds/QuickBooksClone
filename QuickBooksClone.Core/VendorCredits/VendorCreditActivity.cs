using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.VendorCredits;

public sealed class VendorCreditActivity : EntityBase, ITenantEntity
{
    public VendorCreditActivity(Guid vendorId, DateOnly activityDate, decimal amount, VendorCreditAction action, Guid? purchaseBillId = null, Guid? depositAccountId = null, string? paymentMethod = null, string? referenceNumber = null, Guid? companyId = null)
    {
        if (vendorId == Guid.Empty) throw new ArgumentException("Vendor is required.", nameof(vendorId));
        if (amount <= 0) throw new ArgumentOutOfRangeException(nameof(amount), "Amount must be greater than zero.");

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        VendorId = vendorId;
        ActivityDate = activityDate;
        Amount = amount;
        Action = action;
        PurchaseBillId = purchaseBillId;
        DepositAccountId = depositAccountId;
        PaymentMethod = string.IsNullOrWhiteSpace(paymentMethod) ? null : paymentMethod.Trim();
        ReferenceNumber = string.IsNullOrWhiteSpace(referenceNumber) ? $"VCR-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : referenceNumber.Trim();
        Status = VendorCreditStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid VendorId { get; }
    public DateOnly ActivityDate { get; }
    public decimal Amount { get; }
    public VendorCreditAction Action { get; }
    public Guid? PurchaseBillId { get; }
    public Guid? DepositAccountId { get; }
    public string? PaymentMethod { get; }
    public string ReferenceNumber { get; }
    public VendorCreditStatus Status { get; private set; }
    public Guid? PostedTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }

    public void MarkPosted(Guid? transactionId = null)
    {
        if (Status == VendorCreditStatus.Void) throw new InvalidOperationException("Cannot post a void vendor credit activity.");
        if (Status == VendorCreditStatus.Posted) return;
        PostedTransactionId = transactionId;
        PostedAt = DateTimeOffset.UtcNow;
        Status = VendorCreditStatus.Posted;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
