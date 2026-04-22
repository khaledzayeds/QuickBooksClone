namespace QuickBooksClone.Maui.Services.PurchaseBills;

public sealed class PurchaseBillFormModel
{
    public Guid VendorId { get; set; }
    public Guid? InventoryReceiptId { get; set; }
    public DateOnly BillDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public DateOnly DueDate { get; set; } = DateOnly.FromDateTime(DateTime.Today.AddDays(30));
    public PurchaseBillSaveMode SaveMode { get; set; } = PurchaseBillSaveMode.SaveAndPost;
    public List<PurchaseBillLineFormModel> Lines { get; } = [];
}

public sealed class PurchaseBillLineFormModel
{
    public Guid ItemId { get; set; }
    public Guid? InventoryReceiptLineId { get; set; }
    public string? Description { get; set; }
    public decimal Quantity { get; set; } = 1;
    public decimal UnitCost { get; set; }
}
