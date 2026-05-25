using Zayed.Core.Invoices;
using Zayed.Core.Payments;

namespace Zayed.Api.Contracts.SalesWorkflow;

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
