namespace QuickBooksClone.Core.ReceiveInventory;

public sealed record InventoryReceiptSearch(
    string? Search,
    Guid? VendorId,
    Guid? PurchaseOrderId,
    bool IncludeVoid,
    int Page = 1,
    int PageSize = 25);
