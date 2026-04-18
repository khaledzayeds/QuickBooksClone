namespace QuickBooksClone.Maui.Services.VendorPayments;

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
    DateTimeOffset? PostedAt,
    Guid? ReversalTransactionId,
    DateTimeOffset? VoidedAt);
