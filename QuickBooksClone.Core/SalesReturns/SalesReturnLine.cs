namespace QuickBooksClone.Core.SalesReturns;

public sealed class SalesReturnLine
{
    private SalesReturnLine()
    {
        Description = string.Empty;
    }

    public SalesReturnLine(Guid invoiceLineId, Guid itemId, string description, decimal quantity, decimal unitPrice, decimal discountPercent = 0)
    {
        if (invoiceLineId == Guid.Empty)
        {
            throw new ArgumentException("Invoice line is required.", nameof(invoiceLineId));
        }

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

        if (discountPercent is < 0 or > 100)
        {
            throw new ArgumentOutOfRangeException(nameof(discountPercent), "Discount percent must be between 0 and 100.");
        }

        InvoiceLineId = invoiceLineId;
        ItemId = itemId;
        Description = string.IsNullOrWhiteSpace(description) ? "Sales return line" : description.Trim();
        Quantity = quantity;
        UnitPrice = unitPrice;
        DiscountPercent = discountPercent;
    }

    public Guid Id { get; } = Guid.NewGuid();
    public Guid InvoiceLineId { get; }
    public Guid ItemId { get; }
    public string Description { get; }
    public decimal Quantity { get; }
    public decimal UnitPrice { get; }
    public decimal DiscountPercent { get; }
    public decimal GrossAmount => Quantity * UnitPrice;
    public decimal DiscountAmount => GrossAmount * (DiscountPercent / 100);
    public decimal LineTotal => GrossAmount - DiscountAmount;
}
