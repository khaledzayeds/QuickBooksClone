namespace QuickBooksClone.Core.PurchaseBills;

public sealed record PurchaseBillSearch(
    string? Search,
    Guid? VendorId,
    Guid? InventoryReceiptId,
    bool IncludeVoid,
    int Page,
    int PageSize);
