namespace QuickBooksClone.Core.Estimates;

public sealed class EstimateLine
{
    private EstimateLine()
    {
        Description = string.Empty;
    }

    public EstimateLine(
        Guid itemId,
        string description,
        decimal quantity,
        decimal unitPrice,
        Guid? taxCodeId = null,
        decimal taxRatePercent = 0,
        decimal taxAmount = 0)
    {
        if (itemId == Guid.Empty)
        {
            throw new ArgumentException("Item is required.", nameof(itemId));
        }

        if (quantity <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(quantity), "Quantity must be greater than zero.");
        }

        if (unitPrice < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(unitPrice), "Unit price cannot be negative.");
        }

        ItemId = itemId;
        Description = string.IsNullOrWhiteSpace(description) ? "Item" : description.Trim();
        Quantity = quantity;
        UnitPrice = unitPrice;
        TaxCodeId = taxCodeId == Guid.Empty ? null : taxCodeId;
        TaxRatePercent = taxRatePercent;
        TaxAmount = taxAmount;
    }

    public Guid Id { get; } = Guid.NewGuid();
    public Guid ItemId { get; }
    public string Description { get; }
    public decimal Quantity { get; }
    public decimal UnitPrice { get; }
    public Guid? TaxCodeId { get; }
    public decimal TaxRatePercent { get; }
    public decimal TaxAmount { get; }
    public decimal LineTotal => Quantity * UnitPrice;
}
