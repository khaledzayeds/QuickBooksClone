namespace QuickBooksClone.Maui.Services.SalesReturns;

public sealed class SalesReturnFormModel
{
    public Guid InvoiceId { get; set; }
    public DateOnly ReturnDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public List<SalesReturnLineFormModel> Lines { get; } = [];
}

public sealed class SalesReturnLineFormModel
{
    public Guid InvoiceLineId { get; set; }
    public decimal Quantity { get; set; }
    public decimal? UnitPrice { get; set; }
    public decimal DiscountPercent { get; set; }
}
