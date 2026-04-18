namespace QuickBooksClone.Core.VendorCredits;

public sealed record VendorCreditActivityListResult(IReadOnlyList<VendorCreditActivity> Items, int TotalCount, int Page, int PageSize);
