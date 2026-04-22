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

    Task<ProfitAndLossReport> GetProfitAndLossAsync(
        DateOnly fromDate,
        DateOnly toDate,
        bool includeZeroBalances,
        bool includeInactiveAccounts,
        CancellationToken cancellationToken = default);

    Task<AccountsReceivableAgingReport> GetAccountsReceivableAgingAsync(
        DateOnly asOfDate,
        bool includeZeroBalances,
        bool includeInactiveCustomers,
        CancellationToken cancellationToken = default);

    Task<AccountsPayableAgingReport> GetAccountsPayableAgingAsync(
        DateOnly asOfDate,
        bool includeZeroBalances,
        bool includeInactiveVendors,
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

public sealed record ProfitAndLossReport(
    DateOnly FromDate,
    DateOnly ToDate,
    IReadOnlyList<ProfitAndLossSection> Sections,
    decimal TotalIncome,
    decimal TotalCostOfGoodsSold,
    decimal GrossProfit,
    decimal TotalExpenses,
    decimal NetProfit);

public sealed record ProfitAndLossSection(
    string Key,
    string Title,
    IReadOnlyList<ProfitAndLossRow> Items,
    decimal Total);

public sealed record ProfitAndLossRow(
    Guid AccountId,
    string AccountCode,
    string AccountName,
    AccountType AccountType,
    decimal Amount);

public sealed record AccountsReceivableAgingReport(
    DateOnly AsOfDate,
    IReadOnlyList<AccountsReceivableAgingRow> Items,
    decimal Current,
    decimal Days1To30,
    decimal Days31To60,
    decimal Days61To90,
    decimal Over90,
    decimal Total);

public sealed record AccountsReceivableAgingRow(
    Guid CustomerId,
    string CustomerName,
    string Currency,
    decimal Current,
    decimal Days1To30,
    decimal Days31To60,
    decimal Days61To90,
    decimal Over90,
    decimal Total,
    decimal CreditBalance,
    int OpenInvoiceCount);

public sealed record AccountsPayableAgingReport(
    DateOnly AsOfDate,
    IReadOnlyList<AccountsPayableAgingRow> Items,
    decimal Current,
    decimal Days1To30,
    decimal Days31To60,
    decimal Days61To90,
    decimal Over90,
    decimal Total);

public sealed record AccountsPayableAgingRow(
    Guid VendorId,
    string VendorName,
    string Currency,
    decimal Current,
    decimal Days1To30,
    decimal Days31To60,
    decimal Days61To90,
    decimal Over90,
    decimal Total,
    decimal CreditBalance,
    int OpenBillCount);
