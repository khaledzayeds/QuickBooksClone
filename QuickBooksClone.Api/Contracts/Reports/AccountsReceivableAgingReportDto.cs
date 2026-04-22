namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record AccountsReceivableAgingReportDto(
    DateOnly AsOfDate,
    IReadOnlyList<AccountsReceivableAgingRowDto> Items,
    decimal Current,
    decimal Days1To30,
    decimal Days31To60,
    decimal Days61To90,
    decimal Over90,
    decimal Total);
