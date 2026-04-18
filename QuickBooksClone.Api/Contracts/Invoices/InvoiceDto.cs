using QuickBooksClone.Core.Invoices;

namespace QuickBooksClone.Api.Contracts.Invoices;

public sealed record InvoiceDto(
    Guid Id,
    string InvoiceNumber,
    Guid CustomerId,
    string? CustomerName,
    DateOnly InvoiceDate,
    DateOnly DueDate,
    InvoiceStatus Status,
    decimal Subtotal,
    decimal DiscountAmount,
    decimal TaxAmount,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal BalanceDue,
    Guid? PostedTransactionId,
    DateTimeOffset? PostedAt,
    Guid? ReversalTransactionId,
    DateTimeOffset? VoidedAt,
    IReadOnlyList<InvoiceLineDto> Lines);
