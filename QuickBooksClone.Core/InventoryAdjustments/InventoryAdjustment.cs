using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.InventoryAdjustments;

public sealed class InventoryAdjustment : EntityBase, ITenantEntity
{
    private InventoryAdjustment()
    {
        CompanyId = Guid.Empty;
        Reason = string.Empty;
        AdjustmentNumber = string.Empty;
    }

    public InventoryAdjustment(
        Guid itemId,
        Guid adjustmentAccountId,
        DateOnly adjustmentDate,
        decimal quantityChange,
        decimal unitCost,
        string reason,
        string? adjustmentNumber = null,
        Guid? companyId = null)
    {
        if (itemId == Guid.Empty)
        {
            throw new ArgumentException("Item is required.", nameof(itemId));
        }

        if (adjustmentAccountId == Guid.Empty)
        {
            throw new ArgumentException("Adjustment account is required.", nameof(adjustmentAccountId));
        }

        if (quantityChange == 0)
        {
            throw new ArgumentException("Quantity change cannot be zero.", nameof(quantityChange));
        }

        if (unitCost < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(unitCost), "Unit cost cannot be negative.");
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        ItemId = itemId;
        AdjustmentAccountId = adjustmentAccountId;
        AdjustmentDate = adjustmentDate;
        QuantityChange = quantityChange;
        UnitCost = unitCost;
        Reason = string.IsNullOrWhiteSpace(reason) ? "Inventory adjustment" : reason.Trim();
        AdjustmentNumber = string.IsNullOrWhiteSpace(adjustmentNumber) ? $"IA-{DateTimeOffset.UtcNow:yyyyMMddHHmmssfff}" : adjustmentNumber.Trim();
        Status = InventoryAdjustmentStatus.Draft;
    }

    public Guid CompanyId { get; }
    public Guid ItemId { get; }
    public Guid AdjustmentAccountId { get; }
    public DateOnly AdjustmentDate { get; }
    public decimal QuantityChange { get; }
    public decimal UnitCost { get; }
    public decimal TotalCost => Math.Abs(QuantityChange) * UnitCost;
    public string Reason { get; }
    public string AdjustmentNumber { get; }
    public InventoryAdjustmentStatus Status { get; private set; }
    public Guid? PostedTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }

    public void MarkPosted(Guid transactionId)
    {
        if (Status == InventoryAdjustmentStatus.Void)
        {
            throw new InvalidOperationException("Cannot post a void inventory adjustment.");
        }

        if (PostedTransactionId is not null)
        {
            throw new InvalidOperationException("Inventory adjustment is already posted.");
        }

        PostedTransactionId = transactionId;
        PostedAt = DateTimeOffset.UtcNow;
        Status = InventoryAdjustmentStatus.Posted;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
