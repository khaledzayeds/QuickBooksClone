namespace QuickBooksClone.Core.PurchaseBills;

public sealed class PurchaseBillLine
{
    private PurchaseBillLine()
    {
        Description = string.Empty;
    }

    public PurchaseBillLine(Guid itemId, string description, decimal quantity, decimal unitCost, Guid? inventoryReceiptLineId = null, Guid? taxCodeId = null, decimal taxRatePercent = 0, decimal taxAmount = 0)
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
        InventoryReceiptLineId = inventoryReceiptLineId;
        Description = string.IsNullOrWhiteSpace(description) ? "Item" : description.Trim();
        Quantity = quantity;
        UnitCost = unitCost;
        TaxCodeId = taxCodeId == Guid.Empty ? null : taxCodeId;
        TaxRatePercent = Math.Clamp(taxRatePercent, 0, 100);
        TaxAmount = taxAmount < 0 ? throw new ArgumentOutOfRangeException(nameof(taxAmount), "Tax amount cannot be negative.") : taxAmount;
    }

    public Guid Id { get; } = Guid.NewGuid();
    public Guid ItemId { get; }
    public Guid? InventoryReceiptLineId { get; }
    public string Description { get; }
    public decimal Quantity { get; }
    public decimal UnitCost { get; }
    public Guid? TaxCodeId { get; }
    public decimal TaxRatePercent { get; }
    public decimal TaxAmount { get; }
    public decimal LineTotal => Quantity * UnitCost;
}
