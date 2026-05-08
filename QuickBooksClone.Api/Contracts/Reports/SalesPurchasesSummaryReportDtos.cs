namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record SalesSummaryReportDto(
    DateOnly? FromDate,
    DateOnly? ToDate,
    int InvoiceCount,
    int CustomerCount,
    decimal Subtotal,
    decimal TaxAmount,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal BalanceDue,
    IReadOnlyList<SalesSummaryByStatusDto> ByStatus,
    IReadOnlyList<SalesSummaryByCustomerDto> ByCustomer,
    IReadOnlyList<SalesSummaryInvoiceDto> Invoices);

public sealed record SalesSummaryByStatusDto(
    int Status,
    int InvoiceCount,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal BalanceDue);

public sealed record SalesSummaryByCustomerDto(
    Guid CustomerId,
    string CustomerName,
    int InvoiceCount,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal BalanceDue);

public sealed record SalesSummaryInvoiceDto(
    Guid Id,
    string InvoiceNumber,
    DateOnly InvoiceDate,
    DateOnly DueDate,
    string CustomerName,
    int Status,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal BalanceDue);

public sealed record PurchasesSummaryReportDto(
    DateOnly? FromDate,
    DateOnly? ToDate,
    int BillCount,
    int VendorCount,
    decimal Subtotal,
    decimal TaxAmount,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal BalanceDue,
    IReadOnlyList<PurchasesSummaryByStatusDto> ByStatus,
    IReadOnlyList<PurchasesSummaryByVendorDto> ByVendor,
    IReadOnlyList<PurchasesSummaryBillDto> Bills);

public sealed record PurchasesSummaryByStatusDto(
    int Status,
    int BillCount,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal BalanceDue);

public sealed record PurchasesSummaryByVendorDto(
    Guid VendorId,
    string VendorName,
    int BillCount,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal BalanceDue);

public sealed record PurchasesSummaryBillDto(
    Guid Id,
    string BillNumber,
    DateOnly BillDate,
    DateOnly DueDate,
    string VendorName,
    int Status,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal BalanceDue);
