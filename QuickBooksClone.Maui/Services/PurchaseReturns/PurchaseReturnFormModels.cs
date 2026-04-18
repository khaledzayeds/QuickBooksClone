namespace QuickBooksClone.Maui.Services.PurchaseReturns;

public sealed class PurchaseReturnFormModel
{
    public Guid PurchaseBillId { get; set; }
    public DateOnly ReturnDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public List<PurchaseReturnLineFormModel> Lines { get; } = [];
}

public sealed class PurchaseReturnLineFormModel
{
    public Guid PurchaseBillLineId { get; set; }
    public decimal Quantity { get; set; }
    public decimal? UnitCost { get; set; }
}
