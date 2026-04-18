namespace QuickBooksClone.Core.Vendors;

public sealed record VendorListResult(
    IReadOnlyList<Vendor> Items,
    int TotalCount,
    int Page,
    int PageSize);
