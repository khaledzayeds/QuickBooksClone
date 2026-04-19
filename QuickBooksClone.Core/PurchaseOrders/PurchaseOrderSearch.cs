namespace QuickBooksClone.Core.PurchaseOrders;

public sealed record PurchaseOrderSearch(
    string? Search,
    Guid? VendorId,
    bool IncludeClosed,
    bool IncludeCancelled,
    int Page,
    int PageSize);
