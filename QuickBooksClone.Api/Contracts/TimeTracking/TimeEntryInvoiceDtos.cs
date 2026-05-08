namespace QuickBooksClone.Api.Contracts.TimeTracking;

public sealed record CreateInvoiceFromTimeRequest(
    Guid CustomerId,
    DateOnly InvoiceDate,
    DateOnly DueDate,
    IReadOnlyList<Guid> TimeEntryIds,
    bool PostInvoice = true);

public sealed record CreateInvoiceFromTimeResponse(
    Guid InvoiceId,
    string InvoiceNumber,
    Guid CustomerId,
    int TimeEntryCount,
    decimal TotalHours,
    decimal InvoiceTotal,
    bool Posted);
