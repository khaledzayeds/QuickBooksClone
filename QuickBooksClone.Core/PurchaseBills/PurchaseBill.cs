using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.PurchaseBills;

public sealed class PurchaseBill : EntityBase, ITenantEntity
{
    private readonly List<PurchaseBillLine> _lines = [];

    public PurchaseBill(Guid vendorId, DateOnly billDate, DateOnly dueDate, string? billNumber = null, Guid? companyId = null)
    {
        if (vendorId == Guid.Empty)
        {
            throw new ArgumentException("Vendor is required.", nameof(vendorId));
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        VendorId = vendorId;
        BillNumber = string.IsNullOrWhiteSpace(billNumber) ? $"BILL-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : billNumber.Trim();
        BillDate = billDate;
        DueDate = dueDate;
        Status = PurchaseBillStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid VendorId { get; }
    public string BillNumber { get; }
    public DateOnly BillDate { get; }
    public DateOnly DueDate { get; }
    public PurchaseBillStatus Status { get; private set; }
    public IReadOnlyList<PurchaseBillLine> Lines => _lines;
    public decimal TotalAmount => _lines.Sum(line => line.LineTotal);
    public decimal PaidAmount { get; private set; }
    public decimal ReturnedAmount { get; private set; }
    public decimal BalanceDue => Math.Max(0, TotalAmount - ReturnedAmount - PaidAmount);
    public Guid? PostedTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }
    public Guid? ReversalTransactionId { get; private set; }
    public DateTimeOffset? VoidedAt { get; private set; }

    public void AddLine(PurchaseBillLine line)
    {
        if (Status is PurchaseBillStatus.Void or PurchaseBillStatus.Posted)
        {
            throw new InvalidOperationException("Cannot change a void or posted purchase bill.");
        }

        _lines.Add(line);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkPosted(Guid transactionId)
    {
        if (Status == PurchaseBillStatus.Void)
        {
            throw new InvalidOperationException("Cannot post a void purchase bill.");
        }

        if (PostedTransactionId is not null)
        {
            throw new InvalidOperationException("Purchase bill is already posted.");
        }

        PostedTransactionId = transactionId;
        PostedAt = DateTimeOffset.UtcNow;
        Status = PurchaseBillStatus.Posted;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Void(Guid? reversalTransactionId = null)
    {
        if (Status == PurchaseBillStatus.Void)
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
            throw new InvalidOperationException("Cannot void a purchase bill with applied payments.");
        }

        ReversalTransactionId = reversalTransactionId;
        VoidedAt = DateTimeOffset.UtcNow;
        Status = PurchaseBillStatus.Void;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ApplyPayment(decimal amount)
    {
        if (Status is PurchaseBillStatus.Void or PurchaseBillStatus.Draft)
        {
            throw new InvalidOperationException("Cannot apply a payment to a draft or void purchase bill.");
        }

        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Payment amount must be greater than zero.");
        }

        if (amount > BalanceDue)
        {
            throw new InvalidOperationException("Payment amount cannot exceed purchase bill balance.");
        }

        PaidAmount += amount;
        Status = BalanceDue == 0 ? PurchaseBillStatus.Paid : PurchaseBillStatus.PartiallyPaid;
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
        Status = PaidAmount == 0 ? PurchaseBillStatus.Posted : PurchaseBillStatus.PartiallyPaid;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ApplyReturn(decimal amount)
    {
        if (Status is PurchaseBillStatus.Draft or PurchaseBillStatus.Void)
        {
            throw new InvalidOperationException("Cannot apply a return to a draft or void purchase bill.");
        }

        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Return amount must be greater than zero.");
        }

        if (ReturnedAmount + amount > TotalAmount)
        {
            throw new InvalidOperationException("Return amount cannot exceed purchase bill total.");
        }

        ReturnedAmount += amount;
        if (ReturnedAmount == TotalAmount)
        {
            Status = PurchaseBillStatus.Returned;
        }
        else if (BalanceDue == 0)
        {
            Status = PurchaseBillStatus.Paid;
        }
        else if (PaidAmount > 0 || ReturnedAmount > 0)
        {
            Status = PurchaseBillStatus.PartiallyPaid;
        }
        else
        {
            Status = PurchaseBillStatus.Posted;
        }

        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
