using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Payments;

namespace QuickBooksClone.Api.Contracts.SalesWorkflow;

public sealed record InvoicePaymentPlanDto(
    Guid InvoiceId,
    string InvoiceNumber,
    Guid CustomerId,
    string? CustomerName,
    Guid? SalesOrderId,
    string? SalesOrderNumber,
    InvoiceStatus Status,
    bool CanReceivePayment,
    bool IsFullyPaid,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal CreditAppliedAmount,
    decimal ReturnedAmount,
    decimal BalanceDue,
    IReadOnlyList<LinkedPaymentReferenceDto> LinkedPayments);

public sealed record LinkedPaymentReferenceDto(
    Guid Id,
    string PaymentNumber,
    DateOnly PaymentDate,
    PaymentStatus Status,
    decimal Amount);
