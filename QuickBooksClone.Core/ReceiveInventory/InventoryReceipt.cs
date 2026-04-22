using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.ReceiveInventory;

public sealed class InventoryReceipt : SyncDocumentBase, ITenantEntity
{
    private readonly List<InventoryReceiptLine> _lines = [];

    private InventoryReceipt()
    {
        CompanyId = Guid.Empty;
        ReceiptNumber = string.Empty;
    }

    public InventoryReceipt(
        Guid vendorId,
        DateOnly receiptDate,
        Guid? purchaseOrderId = null,
        string? receiptNumber = null,
        Guid? companyId = null)
    {
        if (vendorId == Guid.Empty)
        {
            throw new ArgumentException("Vendor is required.", nameof(vendorId));
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        VendorId = vendorId;
        PurchaseOrderId = purchaseOrderId;
        ReceiptDate = receiptDate;
        ReceiptNumber = string.IsNullOrWhiteSpace(receiptNumber) ? $"RCV-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : receiptNumber.Trim();
        Status = InventoryReceiptStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid VendorId { get; }
    public Guid? PurchaseOrderId { get; }
    public string ReceiptNumber { get; }
    public DateOnly ReceiptDate { get; }
    public InventoryReceiptStatus Status { get; private set; }
    public IReadOnlyList<InventoryReceiptLine> Lines => _lines;
    public decimal TotalAmount => _lines.Sum(line => line.LineTotal);
    public Guid? PostedTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }
    public Guid? ReversalTransactionId { get; private set; }
    public DateTimeOffset? VoidedAt { get; private set; }

    public void AddLine(InventoryReceiptLine line)
    {
        if (Status is InventoryReceiptStatus.Posted or InventoryReceiptStatus.Void)
        {
            throw new InvalidOperationException("Cannot change a posted or void inventory receipt.");
        }

        _lines.Add(line);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkPosted(Guid transactionId)
    {
        if (Status == InventoryReceiptStatus.Void)
        {
            throw new InvalidOperationException("Cannot post a void inventory receipt.");
        }

        if (PostedTransactionId is not null)
        {
            throw new InvalidOperationException("Inventory receipt is already posted.");
        }

        PostedTransactionId = transactionId;
        PostedAt = DateTimeOffset.UtcNow;
        Status = InventoryReceiptStatus.Posted;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Void(Guid? reversalTransactionId = null)
    {
        if (Status == InventoryReceiptStatus.Void)
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
        Status = InventoryReceiptStatus.Void;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
