namespace QuickBooksClone.Maui.Services.SalesReturns;

public sealed record SalesReturnDto(
    Guid Id,
    string ReturnNumber,
    Guid InvoiceId,
    string? InvoiceNumber,
    Guid CustomerId,
    string? CustomerName,
    DateOnly ReturnDate,
    SalesReturnStatus Status,
    decimal TotalAmount,
    Guid? PostedTransactionId,
    DateTimeOffset? PostedAt,
    IReadOnlyList<SalesReturnLineDto> Lines);
