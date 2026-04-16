namespace QuickBooksClone.Api.Contracts.Invoices;

public sealed record InvoiceListResponse(
    IReadOnlyList<InvoiceDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
