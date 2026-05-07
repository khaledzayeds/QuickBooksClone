using QuickBooksClone.Core.Reports;

namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record CashFlowHubReportDto(
    DateOnly AsOfDate,
    DateOnly FromDate,
    DateOnly ToDate,
    string Currency,
    decimal CashBalance,
    decimal TotalAssets,
    decimal TotalLiabilities,
    decimal TotalEquity,
    decimal ExpectedIncoming,
    decimal OverdueIncoming,
    decimal ExpectedOutgoing,
    decimal OverdueOutgoing,
    decimal NetCashAfterOpenItems,
    decimal TotalIncome,
    decimal TotalExpenses,
    decimal NetProfit,
    int OpenInvoiceCount,
    int OpenBillCount,
    IReadOnlyList<CashFlowBucketDto> IncomingBuckets,
    IReadOnlyList<CashFlowBucketDto> OutgoingBuckets,
    IReadOnlyList<CashFlowForecastPointDto> ForecastPoints,
    IReadOnlyList<CashFlowAlertDto> Alerts);

public sealed record CashFlowBucketDto(string Label, decimal Amount);

public sealed record CashFlowForecastPointDto(string Label, decimal Amount);

public sealed record CashFlowAlertDto(string Severity, string Title, string Message);
