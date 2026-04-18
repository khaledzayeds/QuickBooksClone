namespace QuickBooksClone.Core.VendorCredits;

public sealed record VendorCreditActivitySearch(string? Search = null, Guid? VendorId = null, VendorCreditAction? Action = null, bool IncludeVoid = false, int Page = 1, int PageSize = 25);
