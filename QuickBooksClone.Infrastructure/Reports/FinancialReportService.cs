using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
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

    public async Task<ProfitAndLossReport> GetProfitAndLossAsync(
        DateOnly fromDate,
        DateOnly toDate,
        bool includeZeroBalances,
        bool includeInactiveAccounts,
        CancellationToken cancellationToken = default)
    {
        if (toDate < fromDate)
        {
            throw new InvalidOperationException("The report end date cannot be earlier than the start date.");
        }

        var accountsQuery = _db.Accounts.AsNoTracking();
        if (!includeInactiveAccounts)
        {
            accountsQuery = accountsQuery.Where(account => account.IsActive);
        }

        var accounts = await accountsQuery
            .Where(account =>
                account.AccountType == AccountType.Income ||
                account.AccountType == AccountType.OtherIncome ||
                account.AccountType == AccountType.CostOfGoodsSold ||
                account.AccountType == AccountType.Expense ||
                account.AccountType == AccountType.OtherExpense)
            .OrderBy(account => account.Code)
            .ThenBy(account => account.Name)
            .ToListAsync(cancellationToken);

        var balances = await _db.AccountingTransactions
            .AsNoTracking()
            .Where(transaction =>
                transaction.Status == AccountingTransactionStatus.Posted &&
                transaction.TransactionDate >= fromDate &&
                transaction.TransactionDate <= toDate)
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

        var rows = accounts
            .Select(account =>
            {
                balances.TryGetValue(account.Id, out var balance);
                var amount = GetProfitAndLossAmount(account.AccountType, balance.TotalDebit, balance.TotalCredit);

                return new ProfitAndLossRow(
                    account.Id,
                    account.Code,
                    account.Name,
                    account.AccountType,
                    amount);
            })
            .Where(row => includeZeroBalances || row.Amount != 0m)
            .ToList();

        var incomeRows = rows
            .Where(row => row.AccountType is AccountType.Income or AccountType.OtherIncome)
            .OrderBy(row => row.AccountCode)
            .ToList();

        var cogsRows = rows
            .Where(row => row.AccountType == AccountType.CostOfGoodsSold)
            .OrderBy(row => row.AccountCode)
            .ToList();

        var expenseRows = rows
            .Where(row => row.AccountType is AccountType.Expense or AccountType.OtherExpense)
            .OrderBy(row => row.AccountCode)
            .ToList();

        var totalIncome = incomeRows.Sum(row => row.Amount);
        var totalCostOfGoodsSold = cogsRows.Sum(row => row.Amount);
        var grossProfit = totalIncome - totalCostOfGoodsSold;
        var totalExpenses = expenseRows.Sum(row => row.Amount);
        var netProfit = grossProfit - totalExpenses;

        return new ProfitAndLossReport(
            fromDate,
            toDate,
            [
                new ProfitAndLossSection("income", "Income", incomeRows, totalIncome),
                new ProfitAndLossSection("cogs", "Cost of Goods Sold", cogsRows, totalCostOfGoodsSold),
                new ProfitAndLossSection("expenses", "Expenses", expenseRows, totalExpenses)
            ],
            totalIncome,
            totalCostOfGoodsSold,
            grossProfit,
            totalExpenses,
            netProfit);
    }

    public async Task<AccountsReceivableAgingReport> GetAccountsReceivableAgingAsync(
        DateOnly asOfDate,
        bool includeZeroBalances,
        bool includeInactiveCustomers,
        CancellationToken cancellationToken = default)
    {
        var customersQuery = _db.Customers.AsNoTracking();
        if (!includeInactiveCustomers)
        {
            customersQuery = customersQuery.Where(customer => customer.IsActive);
        }

        var customers = await customersQuery
            .OrderBy(customer => customer.DisplayName)
            .ToListAsync(cancellationToken);

        var candidateInvoices = await _db.Invoices
            .AsNoTracking()
            .Where(invoice =>
                invoice.PaymentMode == Core.Invoices.InvoicePaymentMode.Credit &&
                invoice.Status != Core.Invoices.InvoiceStatus.Void &&
                invoice.Status != Core.Invoices.InvoiceStatus.Draft &&
                invoice.InvoiceDate <= asOfDate)
            .ToListAsync(cancellationToken);

        var openInvoices = candidateInvoices
            .Select(invoice => new
            {
                invoice.CustomerId,
                invoice.DueDate,
                Balance = invoice.BalanceDue
            })
            .Where(invoice => invoice.Balance > 0)
            .ToList();

        var invoiceGroups = openInvoices
            .GroupBy(invoice => invoice.CustomerId)
            .ToDictionary(group => group.Key, group => group.ToList());

        var rows = customers
            .Select(customer =>
            {
                invoiceGroups.TryGetValue(customer.Id, out var invoices);
                invoices ??= [];

                decimal current = 0m;
                decimal days1To30 = 0m;
                decimal days31To60 = 0m;
                decimal days61To90 = 0m;
                decimal over90 = 0m;

                foreach (var invoice in invoices)
                {
                    var ageDays = asOfDate.DayNumber - invoice.DueDate.DayNumber;
                    if (ageDays <= 0)
                    {
                        current += invoice.Balance;
                    }
                    else if (ageDays <= 30)
                    {
                        days1To30 += invoice.Balance;
                    }
                    else if (ageDays <= 60)
                    {
                        days31To60 += invoice.Balance;
                    }
                    else if (ageDays <= 90)
                    {
                        days61To90 += invoice.Balance;
                    }
                    else
                    {
                        over90 += invoice.Balance;
                    }
                }

                var total = current + days1To30 + days31To60 + days61To90 + over90;
                return new AccountsReceivableAgingRow(
                    customer.Id,
                    customer.DisplayName,
                    customer.Currency,
                    current,
                    days1To30,
                    days31To60,
                    days61To90,
                    over90,
                    total,
                    customer.CreditBalance,
                    invoices.Count);
            })
            .Where(row => includeZeroBalances || row.Total != 0m || row.CreditBalance != 0m)
            .ToList();

        return new AccountsReceivableAgingReport(
            asOfDate,
            rows,
            rows.Sum(row => row.Current),
            rows.Sum(row => row.Days1To30),
            rows.Sum(row => row.Days31To60),
            rows.Sum(row => row.Days61To90),
            rows.Sum(row => row.Over90),
            rows.Sum(row => row.Total));
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

    private static bool IsProfitAndLossType(AccountType accountType) =>
        accountType is AccountType.Income
            or AccountType.OtherIncome
            or AccountType.CostOfGoodsSold
            or AccountType.Expense
            or AccountType.OtherExpense;

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

    private static decimal GetProfitAndLossAmount(AccountType accountType, decimal totalDebit, decimal totalCredit)
    {
        return accountType switch
        {
            AccountType.Income or
            AccountType.OtherIncome => totalCredit - totalDebit,

            AccountType.CostOfGoodsSold or
            AccountType.Expense or
            AccountType.OtherExpense => totalDebit - totalCredit,

            _ => 0m
        };
    }
}
