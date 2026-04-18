using QuickBooksClone.Core.CustomerCredits;

namespace QuickBooksClone.Api.Contracts.CustomerCredits;

public sealed record CustomerCreditActivityDto(
    Guid Id,
    string ReferenceNumber,
    Guid CustomerId,
    string? CustomerName,
    DateOnly ActivityDate,
    decimal Amount,
    CustomerCreditAction Action,
    Guid? InvoiceId,
    string? InvoiceNumber,
    Guid? RefundAccountId,
    string? RefundAccountName,
    string? PaymentMethod,
    CustomerCreditStatus Status,
    Guid? PostedTransactionId,
    DateTimeOffset? PostedAt);
