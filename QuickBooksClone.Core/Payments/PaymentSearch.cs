namespace QuickBooksClone.Core.Payments;

public sealed record PaymentSearch(
    string? Search,
    Guid? CustomerId,
    Guid? InvoiceId,
    bool IncludeVoid,
    int Page,
    int PageSize);
