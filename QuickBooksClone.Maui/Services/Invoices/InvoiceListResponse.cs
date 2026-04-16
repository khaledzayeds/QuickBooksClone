namespace QuickBooksClone.Maui.Services.Invoices;

public sealed record InvoiceListResponse(
    IReadOnlyList<InvoiceDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
