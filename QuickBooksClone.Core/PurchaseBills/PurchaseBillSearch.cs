namespace QuickBooksClone.Core.PurchaseBills;

public sealed record PurchaseBillSearch(
    string? Search,
    Guid? VendorId,
    bool IncludeVoid,
    int Page,
    int PageSize);
