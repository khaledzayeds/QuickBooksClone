namespace QuickBooksClone.Core.PurchaseReturns;

public sealed record PurchaseReturnSearch(
    string? Search = null,
    Guid? PurchaseBillId = null,
    Guid? VendorId = null,
    bool IncludeVoid = false,
    int Page = 1,
    int PageSize = 25);
