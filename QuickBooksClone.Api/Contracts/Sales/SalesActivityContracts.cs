using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Payments;

namespace QuickBooksClone.Api.Contracts.Sales;

public sealed record CustomerSalesActivityDto(
    Guid CustomerId,
    string CustomerName,
    string Currency,
    decimal OpenBalance,
    decimal CreditBalance,
    IReadOnlyList<CustomerSalesActivityItemDto> RecentInvoices,
    IReadOnlyList<CustomerSalesActivityItemDto> RecentSalesReceipts,
    IReadOnlyList<CustomerPaymentActivityItemDto> RecentPayments,
    IReadOnlyList<string> Warnings);

public sealed record CustomerSalesActivityItemDto(
    Guid Id,
    string Number,
    DateOnly Date,
    DateOnly DueDate,
    InvoiceStatus Status,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal CreditAppliedAmount,
    decimal ReturnedAmount,
    decimal BalanceDue);

public sealed record CustomerPaymentActivityItemDto(
    Guid Id,
    string Number,
    Guid InvoiceId,
    DateOnly PaymentDate,
    PaymentStatus Status,
    decimal Amount,
    string PaymentMethod);
