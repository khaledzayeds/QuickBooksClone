namespace QuickBooksClone.Core.Invoices;

public sealed class InvoiceLine
{
    public InvoiceLine(Guid itemId, string description, decimal quantity, decimal unitPrice, decimal discountPercent = 0)
    {
        if (itemId == Guid.Empty)
        {
            throw new ArgumentException("Item is required.", nameof(itemId));
        }

        if (quantity <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(quantity), "Quantity must be greater than zero.");
        }

        ItemId = itemId;
        Description = string.IsNullOrWhiteSpace(description) ? "Item" : description.Trim();
        Quantity = quantity;
        UnitPrice = unitPrice;
        DiscountPercent = Math.Clamp(discountPercent, 0, 100);
    }

    public Guid Id { get; } = Guid.NewGuid();
    public Guid ItemId { get; }
    public string Description { get; }
    public decimal Quantity { get; }
    public decimal UnitPrice { get; }
    public decimal DiscountPercent { get; }
    public decimal GrossAmount => Quantity * UnitPrice;
    public decimal DiscountAmount => GrossAmount * (DiscountPercent / 100);
    public decimal LineTotal => GrossAmount - DiscountAmount;
}
