namespace QuickBooksClone.Maui.Services.VendorCredits;

public sealed record VendorCreditActivityListResponse(IReadOnlyList<VendorCreditActivityDto> Items, int TotalCount, int Page, int PageSize);
