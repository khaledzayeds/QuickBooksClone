namespace QuickBooksClone.Core.Invoices;

public sealed record InvoiceListResult(
    IReadOnlyList<Invoice> Items,
    int TotalCount,
    int Page,
    int PageSize);
