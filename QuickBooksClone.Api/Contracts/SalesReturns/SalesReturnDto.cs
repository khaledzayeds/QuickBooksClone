using QuickBooksClone.Core.SalesReturns;

namespace QuickBooksClone.Api.Contracts.SalesReturns;

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
