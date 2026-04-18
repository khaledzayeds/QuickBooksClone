using QuickBooksClone.Core.VendorPayments;

namespace QuickBooksClone.Api.Contracts.VendorPayments;

public sealed record VendorPaymentDto(
    Guid Id,
    string PaymentNumber,
    Guid VendorId,
    string? VendorName,
    Guid PurchaseBillId,
    string? PurchaseBillNumber,
    Guid PaymentAccountId,
    string? PaymentAccountName,
    DateOnly PaymentDate,
    decimal Amount,
    string PaymentMethod,
    VendorPaymentStatus Status,
    Guid? PostedTransactionId,
    DateTimeOffset? PostedAt);
