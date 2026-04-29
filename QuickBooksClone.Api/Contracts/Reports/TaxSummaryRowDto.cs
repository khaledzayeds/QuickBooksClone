namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record TaxSummaryRowDto(
    Guid TaxCodeId,
    string TaxCode,
    string TaxCodeName,
    Guid TaxAccountId,
    string? TaxAccountCode,
    string? TaxAccountName,
    decimal RatePercent,
    decimal TaxableSales,
    decimal OutputTax,
    decimal TaxablePurchases,
    decimal InputTax,
    decimal NetTaxPayable);
