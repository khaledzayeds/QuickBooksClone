namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record TrialBalanceReportDto(
    DateOnly AsOfDate,
    IReadOnlyList<TrialBalanceRowDto> Items,
    decimal TotalDebit,
    decimal TotalCredit);
