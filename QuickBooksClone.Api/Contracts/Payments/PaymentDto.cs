using QuickBooksClone.Core.Payments;

namespace QuickBooksClone.Api.Contracts.Payments;

public sealed record PaymentDto(
    Guid Id,
    string PaymentNumber,
    Guid CustomerId,
    string? CustomerName,
    Guid InvoiceId,
    string? InvoiceNumber,
    Guid DepositAccountId,
    string? DepositAccountName,
    DateOnly PaymentDate,
    decimal Amount,
    string PaymentMethod,
    PaymentStatus Status,
    Guid? PostedTransactionId,
    DateTimeOffset? PostedAt,
    Guid? ReversalTransactionId,
    DateTimeOffset? VoidedAt);
