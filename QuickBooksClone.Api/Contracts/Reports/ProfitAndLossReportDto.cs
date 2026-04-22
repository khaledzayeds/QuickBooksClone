namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record ProfitAndLossReportDto(
    DateOnly FromDate,
    DateOnly ToDate,
    IReadOnlyList<ProfitAndLossSectionDto> Sections,
    decimal TotalIncome,
    decimal TotalCostOfGoodsSold,
    decimal GrossProfit,
    decimal TotalExpenses,
    decimal NetProfit);
