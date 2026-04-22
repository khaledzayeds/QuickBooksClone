namespace QuickBooksClone.Core.ReceiveInventory;

public sealed class InventoryReceiptLine
{
    private InventoryReceiptLine()
    {
        Description = string.Empty;
    }

    public InventoryReceiptLine(Guid itemId, string description, decimal quantity, decimal unitCost, Guid? purchaseOrderLineId = null)
    {
        if (itemId == Guid.Empty)
        {
            throw new ArgumentException("Item is required.", nameof(itemId));
        }

        if (quantity <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(quantity), "Quantity must be greater than zero.");
        }

        if (unitCost < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(unitCost), "Unit cost cannot be negative.");
        }

        ItemId = itemId;
        PurchaseOrderLineId = purchaseOrderLineId;
        Description = string.IsNullOrWhiteSpace(description) ? "Item" : description.Trim();
        Quantity = quantity;
        UnitCost = unitCost;
    }

    public Guid Id { get; } = Guid.NewGuid();
    public Guid ItemId { get; }
    public Guid? PurchaseOrderLineId { get; }
    public string Description { get; }
    public decimal Quantity { get; }
    public decimal UnitCost { get; }
    public decimal LineTotal => Quantity * UnitCost;
}
