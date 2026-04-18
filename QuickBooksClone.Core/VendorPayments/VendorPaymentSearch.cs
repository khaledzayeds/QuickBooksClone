namespace QuickBooksClone.Core.VendorPayments;

public sealed record VendorPaymentSearch(
    string? Search,
    Guid? VendorId,
    Guid? PurchaseBillId,
    bool IncludeVoid,
    int Page,
    int PageSize);
