using QuickBooksClone.Core.Invoices;

namespace QuickBooksClone.Api.Contracts.Invoices;

public sealed record InvoiceDto(
    Guid Id,
    string InvoiceNumber,
    Guid CustomerId,
    string? CustomerName,
    Guid? SalesOrderId,
    DateOnly InvoiceDate,
    DateOnly DueDate,
    InvoicePaymentMode PaymentMode,
    Guid? DepositAccountId,
    string? DepositAccountName,
    string? PaymentMethod,
    Guid? ReceiptPaymentId,
    InvoiceStatus Status,
    decimal Subtotal,
    decimal DiscountAmount,
    decimal TaxAmount,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal CreditAppliedAmount,
    decimal ReturnedAmount,
    decimal BalanceDue,
    Guid? PostedTransactionId,
    DateTimeOffset? PostedAt,
    Guid? ReversalTransactionId,
    DateTimeOffset? VoidedAt,
    IReadOnlyList<InvoiceLineDto> Lines);
