using QuickBooksClone.Core.PurchaseBills;

namespace QuickBooksClone.Api.Contracts.PurchaseBills;

public sealed record PurchaseBillDto(
    Guid Id,
    string BillNumber,
    Guid VendorId,
    string? VendorName,
    DateOnly BillDate,
    DateOnly DueDate,
    PurchaseBillStatus Status,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal ReturnedAmount,
    decimal BalanceDue,
    Guid? PostedTransactionId,
    DateTimeOffset? PostedAt,
    Guid? ReversalTransactionId,
    DateTimeOffset? VoidedAt,
    IReadOnlyList<PurchaseBillLineDto> Lines);
