namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record BalanceSheetReportDto(
    DateOnly AsOfDate,
    IReadOnlyList<BalanceSheetSectionDto> Sections,
    decimal TotalAssets,
    decimal TotalLiabilities,
    decimal TotalEquity,
    decimal TotalLiabilitiesAndEquity);
