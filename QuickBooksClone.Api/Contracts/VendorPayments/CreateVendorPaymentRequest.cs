namespace QuickBooksClone.Api.Contracts.VendorPayments;

public sealed record CreateVendorPaymentRequest(
    Guid PurchaseBillId,
    Guid PaymentAccountId,
    DateOnly PaymentDate,
    decimal Amount,
    string? PaymentMethod);
