namespace QuickBooksClone.Maui.Services.ReceiveInventory;

public sealed class InventoryReceiptLineDto
{
    public Guid Id { get; set; }
    public Guid ItemId { get; set; }
    public Guid? PurchaseOrderLineId { get; set; }
    public string Description { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public decimal UnitCost { get; set; }
    public decimal LineTotal { get; set; }
}
