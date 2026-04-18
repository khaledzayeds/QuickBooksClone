namespace QuickBooksClone.Api.Contracts.Vendors;

public sealed record VendorListResponse(
    IReadOnlyList<VendorDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
