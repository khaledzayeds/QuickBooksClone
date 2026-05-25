using Zayed.Core.CustomerCredits;

namespace Zayed.Api.Contracts.CustomerCredits;

public sealed record CreateCustomerCreditActivityRequest(
    Guid CustomerId,
    DateOnly ActivityDate,
    decimal Amount,
    CustomerCreditAction Action,
    Guid? InvoiceId,
    Guid? RefundAccountId,
    string? PaymentMethod);
