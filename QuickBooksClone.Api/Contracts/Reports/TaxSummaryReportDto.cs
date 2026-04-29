namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record TaxSummaryReportDto(
    DateOnly FromDate,
    DateOnly ToDate,
    IReadOnlyList<TaxSummaryRowDto> Items,
    decimal TotalTaxableSales,
    decimal TotalOutputTax,
    decimal TotalTaxablePurchases,
    decimal TotalInputTax,
    decimal NetTaxPayable);
