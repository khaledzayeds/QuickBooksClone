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

public sealed record SalesPrintDataDto(
    Guid DocumentId,
    string DocumentType,
    string DocumentNumber,
    InvoicePaymentMode PaymentMode,
    string Status,
    SalesPrintCompanyDto Company,
    SalesPrintCustomerDto Customer,
    SalesPrintPaymentDto? Payment,
    DateOnly DocumentDate,
    DateOnly DueDate,
    decimal Subtotal,
    decimal DiscountAmount,
    decimal TaxAmount,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal CreditAppliedAmount,
    decimal ReturnedAmount,
    decimal BalanceDue,
    IReadOnlyList<SalesPrintLineDto> Lines,
    IReadOnlyList<SalesPrintSummaryRowDto> SummaryRows,
    DateTimeOffset GeneratedAt,
    string? Notes = null,
    string? Terms = null);

public sealed record SalesPrintCompanyDto(
    string CompanyName,
    string? LegalName,
    string? Email,
    string? Phone,
    string Currency,
    string Country);

public sealed record SalesPrintCustomerDto(
    Guid CustomerId,
    string DisplayName,
    string? Email,
    string? Phone,
    string Currency,
    decimal OpenBalance,
    decimal CreditBalance);

public sealed record SalesPrintPaymentDto(
    Guid? DepositAccountId,
    string? DepositAccountName,
    string? PaymentMethod,
    Guid? LinkedPaymentId);

public sealed record SalesPrintLineDto(
    int LineNumber,
    Guid ItemId,
    string ItemName,
    string Description,
    decimal Quantity,
    decimal UnitPrice,
    decimal DiscountPercent,
    decimal TaxRatePercent,
    decimal TaxAmount,
    decimal LineTotal);

public sealed record SalesPrintSummaryRowDto(string Label, decimal Amount, bool IsStrong = false);
