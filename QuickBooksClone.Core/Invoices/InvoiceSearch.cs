namespace QuickBooksClone.Core.Invoices;

public sealed record InvoiceSearch(
    string? Search,
    Guid? CustomerId = null,
    bool IncludeVoid = false,
    int Page = 1,
    int PageSize = 25);
