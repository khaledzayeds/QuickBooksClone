using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.PurchaseReturns;

public sealed class PurchaseReturn : SyncDocumentBase, ITenantEntity
{
    private readonly List<PurchaseReturnLine> _lines = [];

    private PurchaseReturn()
    {
        CompanyId = Guid.Empty;
        ReturnNumber = string.Empty;
    }

    public PurchaseReturn(Guid purchaseBillId, Guid vendorId, DateOnly returnDate, string? returnNumber = null, Guid? companyId = null)
    {
        if (purchaseBillId == Guid.Empty) throw new ArgumentException("Purchase bill is required.", nameof(purchaseBillId));
        if (vendorId == Guid.Empty) throw new ArgumentException("Vendor is required.", nameof(vendorId));

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        PurchaseBillId = purchaseBillId;
        VendorId = vendorId;
        ReturnDate = returnDate;
        ReturnNumber = string.IsNullOrWhiteSpace(returnNumber) ? $"PR-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : returnNumber.Trim();
        Status = PurchaseReturnStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid PurchaseBillId { get; }
    public Guid VendorId { get; }
    public DateOnly ReturnDate { get; }
    public string ReturnNumber { get; }
    public PurchaseReturnStatus Status { get; private set; }
    public IReadOnlyList<PurchaseReturnLine> Lines => _lines;
    public decimal TotalAmount => _lines.Sum(line => line.LineTotal);
    public Guid? PostedTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }

    public void AddLine(PurchaseReturnLine line)
    {
        if (Status != PurchaseReturnStatus.Draft) throw new InvalidOperationException("Cannot change a posted or void purchase return.");
        _lines.Add(line);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkPosted(Guid transactionId)
    {
        if (Status == PurchaseReturnStatus.Void) throw new InvalidOperationException("Cannot post a void purchase return.");
        if (PostedTransactionId is not null) throw new InvalidOperationException("Purchase return is already posted.");
        PostedTransactionId = transactionId;
        PostedAt = DateTimeOffset.UtcNow;
        Status = PurchaseReturnStatus.Posted;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
