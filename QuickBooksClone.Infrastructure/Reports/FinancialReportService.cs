using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Reports;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Infrastructure.Reports;

public sealed class FinancialReportService : IFinancialReportService
{
    private readonly QuickBooksCloneDbContext _db;

    public FinancialReportService(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    public async Task<TrialBalanceReport> GetTrialBalanceAsync(
        DateOnly asOfDate,
        bool includeZeroBalances,
        bool includeInactiveAccounts,
        CancellationToken cancellationToken = default)
    {
        var (accounts, balances) = await LoadBalancesAsync(asOfDate, includeInactiveAccounts, cancellationToken);

        var rows = accounts
            .Select(account =>
            {
                balances.TryGetValue(account.Id, out var balance);
                var net = balance.TotalDebit - balance.TotalCredit;
                var closingDebit = net > 0 ? net : 0m;
                var closingCredit = net < 0 ? Math.Abs(net) : 0m;

                return new TrialBalanceRow(
                    account.Id,
                    account.Code,
                    account.Name,
                    account.AccountType,
                    balance.TotalDebit,
                    balance.TotalCredit,
                    closingDebit,
                    closingCredit);
            })
            .Where(row => includeZeroBalances || row.TotalDebit != 0m || row.TotalCredit != 0m)
            .ToList();

        return new TrialBalanceReport(
            asOfDate,
            rows,
            rows.Sum(row => row.ClosingDebit),
            rows.Sum(row => row.ClosingCredit));
    }

    public async Task<BalanceSheetReport> GetBalanceSheetAsync(
        DateOnly asOfDate,
        bool includeZeroBalances,
        bool includeInactiveAccounts,
        CancellationToken cancellationToken = default)
    {
        var (accounts, balances) = await LoadBalancesAsync(asOfDate, includeInactiveAccounts, cancellationToken);

        var rows = accounts
            .Select(account =>
            {
                balances.TryGetValue(account.Id, out var balance);
                var amount = GetBalanceSheetAmount(account.AccountType, balance.TotalDebit, balance.TotalCredit);

                return new BalanceSheetRow(
                    account.Id,
                    account.Code,
                    account.Name,
                    account.AccountType,
                    amount);
            })
            .Where(row => IsBalanceSheetType(row.AccountType))
            .Where(row => includeZeroBalances || row.Amount != 0m)
            .ToList();

        var assetRows = rows
            .Where(row => IsAssetType(row.AccountType))
            .OrderBy(row => row.AccountCode)
            .ToList();

        var liabilityRows = rows
            .Where(row => IsLiabilityType(row.AccountType))
            .OrderBy(row => row.AccountCode)
            .ToList();

        var equityRows = rows
            .Where(row => row.AccountType == AccountType.Equity)
            .OrderBy(row => row.AccountCode)
            .ToList();

        var totalAssets = assetRows.Sum(row => row.Amount);
        var totalLiabilities = liabilityRows.Sum(row => row.Amount);
        var totalEquity = equityRows.Sum(row => row.Amount);

        return new BalanceSheetReport(
            asOfDate,
            [
                new BalanceSheetSection("assets", "Assets", assetRows, totalAssets),
                new BalanceSheetSection("liabilities", "Liabilities", liabilityRows, totalLiabilities),
                new BalanceSheetSection("equity", "Equity", equityRows, totalEquity)
            ],
            totalAssets,
            totalLiabilities,
            totalEquity,
            totalLiabilities + totalEquity);
    }

    private async Task<(List<QuickBooksClone.Core.Accounting.Account> Accounts, Dictionary<Guid, (decimal TotalDebit, decimal TotalCredit)> Balances)>
        LoadBalancesAsync(
            DateOnly asOfDate,
            bool includeInactiveAccounts,
            CancellationToken cancellationToken)
    {
        var accountsQuery = _db.Accounts.AsNoTracking();
        if (!includeInactiveAccounts)
        {
            accountsQuery = accountsQuery.Where(account => account.IsActive);
        }

        var accounts = await accountsQuery
            .OrderBy(account => account.Code)
            .ThenBy(account => account.Name)
            .ToListAsync(cancellationToken);

        var balances = await _db.AccountingTransactions
            .AsNoTracking()
            .Where(transaction =>
                transaction.Status == AccountingTransactionStatus.Posted &&
                transaction.TransactionDate <= asOfDate)
            .SelectMany(
                transaction => transaction.Lines,
                (transaction, line) => new
                {
                    line.AccountId,
                    line.Debit,
                    line.Credit
                })
            .GroupBy(line => line.AccountId)
            .Select(group => new
            {
                AccountId = group.Key,
                TotalDebit = group.Sum(line => line.Debit),
                TotalCredit = group.Sum(line => line.Credit)
            })
            .ToDictionaryAsync(
                entry => entry.AccountId,
                entry => (entry.TotalDebit, entry.TotalCredit),
                cancellationToken);

        return (accounts, balances);
    }

    private static bool IsBalanceSheetType(AccountType accountType) =>
        IsAssetType(accountType) ||
        IsLiabilityType(accountType) ||
        accountType == AccountType.Equity;

    private static bool IsAssetType(AccountType accountType) =>
        accountType is AccountType.Bank
            or AccountType.AccountsReceivable
            or AccountType.OtherCurrentAsset
            or AccountType.InventoryAsset
            or AccountType.FixedAsset;

    private static bool IsLiabilityType(AccountType accountType) =>
        accountType is AccountType.AccountsPayable
            or AccountType.CreditCard
            or AccountType.OtherCurrentLiability
            or AccountType.LongTermLiability;

    private static decimal GetBalanceSheetAmount(AccountType accountType, decimal totalDebit, decimal totalCredit)
    {
        return accountType switch
        {
            AccountType.Bank or
            AccountType.AccountsReceivable or
            AccountType.OtherCurrentAsset or
            AccountType.InventoryAsset or
            AccountType.FixedAsset => totalDebit - totalCredit,

            AccountType.AccountsPayable or
            AccountType.CreditCard or
            AccountType.OtherCurrentLiability or
            AccountType.LongTermLiability or
            AccountType.Equity => totalCredit - totalDebit,

            _ => 0m
        };
    }
}
