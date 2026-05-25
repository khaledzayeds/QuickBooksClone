using Zayed.Core.VendorCredits;

namespace Zayed.Api.Contracts.VendorCredits;

public sealed record VendorCreditActivityDto(
    Guid Id,
    string ReferenceNumber,
    Guid VendorId,
    string? VendorName,
    DateOnly ActivityDate,
    decimal Amount,
    VendorCreditAction Action,
    Guid? PurchaseBillId,
    string? PurchaseBillNumber,
    Guid? DepositAccountId,
    string? DepositAccountName,
    string? PaymentMethod,
    VendorCreditStatus Status,
    Guid? PostedTransactionId,
    DateTimeOffset? PostedAt);
