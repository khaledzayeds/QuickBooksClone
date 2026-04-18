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
    public Guid? PostedTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }

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
}
