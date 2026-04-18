namespace QuickBooksClone.Core.SalesReturns;

public sealed record SalesReturnSearch(
    string? Search = null,
    Guid? InvoiceId = null,
    Guid? CustomerId = null,
    bool IncludeVoid = false,
    int Page = 1,
    int PageSize = 25);
