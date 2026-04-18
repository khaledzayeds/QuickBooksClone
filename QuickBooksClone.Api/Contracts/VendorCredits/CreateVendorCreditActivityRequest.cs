using QuickBooksClone.Core.VendorCredits;

namespace QuickBooksClone.Api.Contracts.VendorCredits;

public sealed record CreateVendorCreditActivityRequest(
    Guid VendorId,
    DateOnly ActivityDate,
    decimal Amount,
    VendorCreditAction Action,
    Guid? PurchaseBillId,
    Guid? DepositAccountId,
    string? PaymentMethod);
