namespace QuickBooksClone.Maui.Services.InventoryAdjustments;

public sealed class InventoryAdjustmentFormModel
{
    public Guid ItemId { get; set; }
    public Guid AdjustmentAccountId { get; set; }
    public DateOnly AdjustmentDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public decimal QuantityChange { get; set; }
    public decimal? UnitCost { get; set; }
    public string? Reason { get; set; }
}
