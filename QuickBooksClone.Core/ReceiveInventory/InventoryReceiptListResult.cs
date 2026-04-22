namespace QuickBooksClone.Core.ReceiveInventory;

public sealed record InventoryReceiptListResult(
    IReadOnlyList<InventoryReceipt> Items,
    int TotalCount,
    int Page,
    int PageSize);
