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
    decimal BalanceDue,
    IReadOnlyList<InvoiceLineDto> Lines);
