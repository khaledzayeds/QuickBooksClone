using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.VendorPayments;

namespace QuickBooksClone.Api.Contracts.PurchaseWorkflow;

public sealed record PurchaseBillPaymentPlanDto(
    Guid PurchaseBillId,
    string BillNumber,
    Guid VendorId,
    string? VendorName,
    PurchaseBillStatus Status,
    bool CanPay,
    bool IsFullyPaid,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal CreditAppliedAmount,
    decimal ReturnedAmount,
    decimal BalanceDue,
    IReadOnlyList<LinkedVendorPaymentReferenceDto> LinkedPayments);

public sealed record LinkedVendorPaymentReferenceDto(
    Guid Id,
    string PaymentNumber,
    DateOnly PaymentDate,
    VendorPaymentStatus Status,
    decimal Amount);
