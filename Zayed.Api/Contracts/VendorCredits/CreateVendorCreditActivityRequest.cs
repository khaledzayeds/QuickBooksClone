using Zayed.Core.VendorCredits;

namespace Zayed.Api.Contracts.VendorCredits;

public sealed record CreateVendorCreditActivityRequest(
    Guid VendorId,
    DateOnly ActivityDate,
    decimal Amount,
    VendorCreditAction Action,
    Guid? PurchaseBillId,
    Guid? DepositAccountId,
    string? PaymentMethod);
