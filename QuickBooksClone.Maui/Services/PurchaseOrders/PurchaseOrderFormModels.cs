namespace QuickBooksClone.Maui.Services.PurchaseOrders;

public sealed class PurchaseOrderFormModel
{
    public Guid VendorId { get; set; }
    public DateOnly OrderDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public DateOnly ExpectedDate { get; set; } = DateOnly.FromDateTime(DateTime.Today.AddDays(7));
    public PurchaseOrderSaveMode SaveMode { get; set; } = PurchaseOrderSaveMode.SaveAsOpen;
    public List<PurchaseOrderLineFormModel> Lines { get; } = [];
}

public sealed class PurchaseOrderLineFormModel
{
    public Guid ItemId { get; set; }
    public string? Description { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitCost { get; set; }
}
