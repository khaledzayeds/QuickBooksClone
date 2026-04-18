using QuickBooksClone.Core.CustomerCredits;

namespace QuickBooksClone.Api.Contracts.CustomerCredits;

public sealed record CreateCustomerCreditActivityRequest(
    Guid CustomerId,
    DateOnly ActivityDate,
    decimal Amount,
    CustomerCreditAction Action,
    Guid? InvoiceId,
    Guid? RefundAccountId,
    string? PaymentMethod);
