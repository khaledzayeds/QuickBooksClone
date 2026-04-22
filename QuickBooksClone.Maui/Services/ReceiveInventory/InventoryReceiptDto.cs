namespace QuickBooksClone.Maui.Services.ReceiveInventory;

public sealed class InventoryReceiptDto
{
    public Guid Id { get; set; }
    public string ReceiptNumber { get; set; } = string.Empty;
    public Guid VendorId { get; set; }
    public string? VendorName { get; set; }
    public Guid? PurchaseOrderId { get; set; }
    public string? PurchaseOrderNumber { get; set; }
    public DateOnly ReceiptDate { get; set; }
    public InventoryReceiptStatus Status { get; set; }
    public decimal TotalAmount { get; set; }
    public Guid? PostedTransactionId { get; set; }
    public DateTimeOffset? PostedAt { get; set; }
    public Guid? ReversalTransactionId { get; set; }
    public DateTimeOffset? VoidedAt { get; set; }
    public List<InventoryReceiptLineDto> Lines { get; set; } = [];
}
