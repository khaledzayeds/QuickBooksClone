namespace QuickBooksClone.Core.PurchaseReturns;

public sealed class PurchaseReturnLine
{
    private PurchaseReturnLine()
    {
        Description = string.Empty;
    }

    public PurchaseReturnLine(Guid purchaseBillLineId, Guid itemId, string description, decimal quantity, decimal unitCost)
    {
        if (purchaseBillLineId == Guid.Empty) throw new ArgumentException("Purchase bill line is required.", nameof(purchaseBillLineId));
        if (itemId == Guid.Empty) throw new ArgumentException("Item is required.", nameof(itemId));
        if (quantity <= 0) throw new ArgumentOutOfRangeException(nameof(quantity), "Quantity must be greater than zero.");
        if (unitCost < 0) throw new ArgumentOutOfRangeException(nameof(unitCost), "Unit cost cannot be negative.");

        PurchaseBillLineId = purchaseBillLineId;
        ItemId = itemId;
        Description = string.IsNullOrWhiteSpace(description) ? "Purchase return line" : description.Trim();
        Quantity = quantity;
        UnitCost = unitCost;
    }

    public Guid Id { get; } = Guid.NewGuid();
    public Guid PurchaseBillLineId { get; }
    public Guid ItemId { get; }
    public string Description { get; }
    public decimal Quantity { get; }
    public decimal UnitCost { get; }
    public decimal LineTotal => Quantity * UnitCost;
}
