using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Maui.Services.ReceiveInventory;

public sealed class InventoryReceiptFormModel
{
    [Required]
    public Guid VendorId { get; set; }
    public Guid? PurchaseOrderId { get; set; }
    public DateOnly ReceiptDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public InventoryReceiptSaveMode SaveMode { get; set; } = InventoryReceiptSaveMode.SaveAndPost;
    public List<InventoryReceiptLineFormModel> Lines { get; set; } = [];
}

public sealed class InventoryReceiptLineFormModel
{
    [Required]
    public Guid ItemId { get; set; }
    public Guid? PurchaseOrderLineId { get; set; }
    public string? Description { get; set; }
    [Range(typeof(decimal), "0.0001", "999999999")]
    public decimal Quantity { get; set; }
    [Range(typeof(decimal), "0", "999999999")]
    public decimal UnitCost { get; set; }
}
