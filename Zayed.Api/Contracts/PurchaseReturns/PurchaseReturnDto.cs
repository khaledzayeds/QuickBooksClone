using Zayed.Core.PurchaseReturns;

namespace Zayed.Api.Contracts.PurchaseReturns;

public sealed record PurchaseReturnDto(
    Guid Id,
    string ReturnNumber,
    Guid PurchaseBillId,
    string? PurchaseBillNumber,
    Guid VendorId,
    string? VendorName,
    DateOnly ReturnDate,
    PurchaseReturnStatus Status,
    decimal TotalAmount,
    Guid? PostedTransactionId,
    DateTimeOffset? PostedAt,
    Guid? ReversalTransactionId,
    DateTimeOffset? VoidedAt,
    IReadOnlyList<PurchaseReturnLineDto> Lines);
