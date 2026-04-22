using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Core.Reports;

public interface IFinancialReportService
{
    Task<TrialBalanceReport> GetTrialBalanceAsync(
        DateOnly asOfDate,
        bool includeZeroBalances,
        bool includeInactiveAccounts,
        CancellationToken cancellationToken = default);

    Task<BalanceSheetReport> GetBalanceSheetAsync(
        DateOnly asOfDate,
        bool includeZeroBalances,
        bool includeInactiveAccounts,
        CancellationToken cancellationToken = default);
}

public sealed record TrialBalanceReport(
    DateOnly AsOfDate,
    IReadOnlyList<TrialBalanceRow> Items,
    decimal TotalDebit,
    decimal TotalCredit);

public sealed record TrialBalanceRow(
    Guid AccountId,
    string AccountCode,
    string AccountName,
    AccountType AccountType,
    decimal TotalDebit,
    decimal TotalCredit,
    decimal ClosingDebit,
    decimal ClosingCredit);

public sealed record BalanceSheetReport(
    DateOnly AsOfDate,
    IReadOnlyList<BalanceSheetSection> Sections,
    decimal TotalAssets,
    decimal TotalLiabilities,
    decimal TotalEquity,
    decimal TotalLiabilitiesAndEquity);

public sealed record BalanceSheetSection(
    string Key,
    string Title,
    IReadOnlyList<BalanceSheetRow> Items,
    decimal Total);

public sealed record BalanceSheetRow(
    Guid AccountId,
    string AccountCode,
    string AccountName,
    AccountType AccountType,
    decimal Amount);
