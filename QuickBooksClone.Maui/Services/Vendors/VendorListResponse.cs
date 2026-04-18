namespace QuickBooksClone.Maui.Services.Vendors;

public sealed record VendorListResponse(
    IReadOnlyList<VendorDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
