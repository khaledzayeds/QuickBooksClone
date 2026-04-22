namespace QuickBooksClone.Api.Contracts.ReceiveInventory;

public sealed record InventoryReceiptListResponse(
    IReadOnlyList<InventoryReceiptDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
