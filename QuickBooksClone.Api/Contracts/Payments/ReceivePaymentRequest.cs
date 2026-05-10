namespace QuickBooksClone.Api.Contracts.Payments;

public sealed record ReceivePaymentAllocationRequest(
    Guid InvoiceId,
    decimal Amount);

public sealed record ReceivePaymentRequest(
    Guid CustomerId,
    Guid DepositAccountId,
    DateOnly PaymentDate,
    string? PaymentMethod,
    IReadOnlyList<ReceivePaymentAllocationRequest> Allocations);
