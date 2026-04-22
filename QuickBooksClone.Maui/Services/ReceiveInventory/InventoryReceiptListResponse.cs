namespace QuickBooksClone.Maui.Services.ReceiveInventory;

public sealed class InventoryReceiptListResponse
{
    public List<InventoryReceiptDto> Items { get; set; } = [];
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}
