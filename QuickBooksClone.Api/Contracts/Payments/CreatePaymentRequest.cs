namespace QuickBooksClone.Api.Contracts.Payments;

public sealed record CreatePaymentRequest(
    Guid InvoiceId,
    Guid DepositAccountId,
    DateOnly PaymentDate,
    decimal Amount,
    string? PaymentMethod);
