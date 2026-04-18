namespace QuickBooksClone.Api.Contracts.VendorCredits;

public sealed record VendorCreditActivityListResponse(IReadOnlyList<VendorCreditActivityDto> Items, int TotalCount, int Page, int PageSize);
