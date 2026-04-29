using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.InventoryAdjustments;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.PurchaseReturns;
using QuickBooksClone.Core.Reports;
using QuickBooksClone.Core.ReceiveInventory;
using QuickBooksClone.Core.SalesReturns;
using QuickBooksClone.Core.Vendors;
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
                invoice.PostedTransactionId != null &&
                invoice.Status != Core.Invoices.InvoiceStatus.Void &&
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

    public async Task<AccountsPayableAgingReport> GetAccountsPayableAgingAsync(
        DateOnly asOfDate,
        bool includeZeroBalances,
        bool includeInactiveVendors,
        CancellationToken cancellationToken = default)
    {
        var vendorsQuery = _db.Vendors.AsNoTracking();
        if (!includeInactiveVendors)
        {
            vendorsQuery = vendorsQuery.Where(vendor => vendor.IsActive);
        }

        var vendors = await vendorsQuery
            .OrderBy(vendor => vendor.DisplayName)
            .ToListAsync(cancellationToken);

        var candidateBills = await _db.PurchaseBills
            .AsNoTracking()
            .Where(bill =>
                bill.PostedTransactionId != null &&
                bill.Status != Core.PurchaseBills.PurchaseBillStatus.Void &&
                bill.BillDate <= asOfDate)
            .ToListAsync(cancellationToken);

        var openBills = candidateBills
            .Select(bill => new
            {
                bill.VendorId,
                bill.DueDate,
                Balance = bill.BalanceDue
            })
            .Where(bill => bill.Balance > 0)
            .ToList();

        var billGroups = openBills
            .GroupBy(bill => bill.VendorId)
            .ToDictionary(group => group.Key, group => group.ToList());

        var rows = vendors
            .Select(vendor =>
            {
                billGroups.TryGetValue(vendor.Id, out var bills);
                bills ??= [];

                decimal current = 0m;
                decimal days1To30 = 0m;
                decimal days31To60 = 0m;
                decimal days61To90 = 0m;
                decimal over90 = 0m;

                foreach (var bill in bills)
                {
                    var ageDays = asOfDate.DayNumber - bill.DueDate.DayNumber;
                    if (ageDays <= 0)
                    {
                        current += bill.Balance;
                    }
                    else if (ageDays <= 30)
                    {
                        days1To30 += bill.Balance;
                    }
                    else if (ageDays <= 60)
                    {
                        days31To60 += bill.Balance;
                    }
                    else if (ageDays <= 90)
                    {
                        days61To90 += bill.Balance;
                    }
                    else
                    {
                        over90 += bill.Balance;
                    }
                }

                var total = current + days1To30 + days31To60 + days61To90 + over90;
                return new AccountsPayableAgingRow(
                    vendor.Id,
                    vendor.DisplayName,
                    vendor.Currency,
                    current,
                    days1To30,
                    days31To60,
                    days61To90,
                    over90,
                    total,
                    vendor.CreditBalance,
                    bills.Count);
            })
            .Where(row => includeZeroBalances || row.Total != 0m || row.CreditBalance != 0m)
            .ToList();

        return new AccountsPayableAgingReport(
            asOfDate,
            rows,
            rows.Sum(row => row.Current),
            rows.Sum(row => row.Days1To30),
            rows.Sum(row => row.Days31To60),
            rows.Sum(row => row.Days61To90),
            rows.Sum(row => row.Over90),
            rows.Sum(row => row.Total));
    }

    public async Task<InventoryValuationReport> GetInventoryValuationAsync(
        DateOnly fromDate,
        DateOnly toDate,
        bool includeZeroBalances,
        bool includeInactiveItems,
        CancellationToken cancellationToken = default)
    {
        if (toDate < fromDate)
        {
            throw new InvalidOperationException("The report end date cannot be earlier than the start date.");
        }

        var itemsQuery = _db.Items
            .AsNoTracking()
            .Where(item => item.ItemType == ItemType.Inventory);

        if (!includeInactiveItems)
        {
            itemsQuery = itemsQuery.Where(item => item.IsActive);
        }

        var items = await itemsQuery
            .OrderBy(item => item.Name)
            .ThenBy(item => item.Sku)
            .ToListAsync(cancellationToken);

        var movements = await LoadInventoryMovementsAsync(cancellationToken);

        var movementGroups = movements
            .GroupBy(movement => movement.ItemId)
            .ToDictionary(group => group.Key, group => group.ToList());

        var rows = items
            .Select(item =>
            {
                movementGroups.TryGetValue(item.Id, out var itemMovements);
                itemMovements ??= [];

                var periodMovements = itemMovements
                    .Where(movement => movement.MovementDate >= fromDate && movement.MovementDate <= toDate)
                    .ToList();

                var futureMovementsFromDate = itemMovements
                    .Where(movement => movement.MovementDate >= fromDate)
                    .Sum(movement => movement.QuantityDelta);

                var futureMovementsAfterToDate = itemMovements
                    .Where(movement => movement.MovementDate > toDate)
                    .Sum(movement => movement.QuantityDelta);

                var openingQuantity = item.QuantityOnHand - futureMovementsFromDate;
                var closingQuantity = item.QuantityOnHand - futureMovementsAfterToDate;
                var quantityIn = periodMovements.Where(movement => movement.QuantityDelta > 0m).Sum(movement => movement.QuantityDelta);
                var quantityOut = periodMovements.Where(movement => movement.QuantityDelta < 0m).Sum(movement => Math.Abs(movement.QuantityDelta));
                var quantityInValue = periodMovements.Where(movement => movement.QuantityDelta > 0m).Sum(movement => movement.QuantityDelta * movement.UnitCost);
                var quantityOutValue = periodMovements.Where(movement => movement.QuantityDelta < 0m).Sum(movement => Math.Abs(movement.QuantityDelta) * movement.UnitCost);
                var openingValue = openingQuantity * item.PurchasePrice;
                var closingValue = closingQuantity * item.PurchasePrice;

                return new InventoryValuationRow(
                    item.Id,
                    item.Name,
                    item.Sku,
                    item.Unit,
                    item.PurchasePrice,
                    openingQuantity,
                    quantityIn,
                    quantityOut,
                    closingQuantity,
                    openingValue,
                    quantityInValue,
                    quantityOutValue,
                    closingValue);
            })
            .Where(row =>
                includeZeroBalances ||
                row.OpeningQuantity != 0m ||
                row.QuantityIn != 0m ||
                row.QuantityOut != 0m ||
                row.ClosingQuantity != 0m ||
                row.OpeningValue != 0m ||
                row.ClosingValue != 0m)
            .ToList();

        return new InventoryValuationReport(
            fromDate,
            toDate,
            rows,
            rows.Sum(row => row.OpeningQuantity),
            rows.Sum(row => row.QuantityIn),
            rows.Sum(row => row.QuantityOut),
            rows.Sum(row => row.ClosingQuantity),
            rows.Sum(row => row.OpeningValue),
            rows.Sum(row => row.QuantityInValue),
            rows.Sum(row => row.QuantityOutValue),
            rows.Sum(row => row.ClosingValue));
    }

    public async Task<TaxSummaryReport> GetTaxSummaryAsync(
        DateOnly fromDate,
        DateOnly toDate,
        bool includeZeroRows,
        CancellationToken cancellationToken = default)
    {
        if (toDate < fromDate)
        {
            throw new InvalidOperationException("The report end date cannot be earlier than the start date.");
        }

        var taxCodes = await _db.TaxCodes
            .AsNoTracking()
            .OrderBy(taxCode => taxCode.Code)
            .ThenBy(taxCode => taxCode.Name)
            .ToListAsync(cancellationToken);

        var taxAccountIds = taxCodes.Select(taxCode => taxCode.TaxAccountId).Distinct().ToList();
        var taxAccounts = await _db.Accounts
            .AsNoTracking()
            .Where(account => taxAccountIds.Contains(account.Id))
            .ToDictionaryAsync(account => account.Id, cancellationToken);

        var salesTax = await _db.Invoices
            .AsNoTracking()
            .Where(invoice =>
                invoice.PostedTransactionId != null &&
                invoice.Status != Core.Invoices.InvoiceStatus.Void &&
                invoice.InvoiceDate >= fromDate &&
                invoice.InvoiceDate <= toDate)
            .SelectMany(
                invoice => invoice.Lines,
                (invoice, line) => new
                {
                    line.TaxCodeId,
                    TaxableAmount = line.Quantity * line.UnitPrice - (line.Quantity * line.UnitPrice * line.DiscountPercent / 100m),
                    line.TaxAmount
                })
            .Where(line => line.TaxCodeId != null)
            .GroupBy(line => line.TaxCodeId!.Value)
            .Select(group => new
            {
                TaxCodeId = group.Key,
                TaxableAmount = group.Sum(line => line.TaxableAmount),
                TaxAmount = group.Sum(line => line.TaxAmount)
            })
            .ToDictionaryAsync(
                entry => entry.TaxCodeId,
                entry => (entry.TaxableAmount, entry.TaxAmount),
                cancellationToken);

        var purchaseTax = await _db.PurchaseBills
            .AsNoTracking()
            .Where(bill =>
                bill.PostedTransactionId != null &&
                bill.Status != PurchaseBillStatus.Void &&
                bill.BillDate >= fromDate &&
                bill.BillDate <= toDate)
            .SelectMany(
                bill => bill.Lines,
                (bill, line) => new
                {
                    line.TaxCodeId,
                    TaxableAmount = line.Quantity * line.UnitCost,
                    line.TaxAmount
                })
            .Where(line => line.TaxCodeId != null)
            .GroupBy(line => line.TaxCodeId!.Value)
            .Select(group => new
            {
                TaxCodeId = group.Key,
                TaxableAmount = group.Sum(line => line.TaxableAmount),
                TaxAmount = group.Sum(line => line.TaxAmount)
            })
            .ToDictionaryAsync(
                entry => entry.TaxCodeId,
                entry => (entry.TaxableAmount, entry.TaxAmount),
                cancellationToken);

        var activeTaxCodeIds = salesTax.Keys.Concat(purchaseTax.Keys).ToHashSet();
        var rows = taxCodes
            .Where(taxCode => includeZeroRows || activeTaxCodeIds.Contains(taxCode.Id))
            .Select(taxCode =>
            {
                salesTax.TryGetValue(taxCode.Id, out var sales);
                purchaseTax.TryGetValue(taxCode.Id, out var purchases);
                taxAccounts.TryGetValue(taxCode.TaxAccountId, out var taxAccount);

                return new TaxSummaryRow(
                    taxCode.Id,
                    taxCode.Code,
                    taxCode.Name,
                    taxCode.TaxAccountId,
                    taxAccount?.Code,
                    taxAccount?.Name,
                    taxCode.RatePercent,
                    sales.TaxableAmount,
                    sales.TaxAmount,
                    purchases.TaxableAmount,
                    purchases.TaxAmount,
                    sales.TaxAmount - purchases.TaxAmount);
            })
            .Where(row =>
                includeZeroRows ||
                row.TaxableSales != 0m ||
                row.OutputTax != 0m ||
                row.TaxablePurchases != 0m ||
                row.InputTax != 0m)
            .ToList();

        var totalOutputTax = rows.Sum(row => row.OutputTax);
        var totalInputTax = rows.Sum(row => row.InputTax);

        return new TaxSummaryReport(
            fromDate,
            toDate,
            rows,
            rows.Sum(row => row.TaxableSales),
            totalOutputTax,
            rows.Sum(row => row.TaxablePurchases),
            totalInputTax,
            totalOutputTax - totalInputTax);
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

    private async Task<List<InventoryMovement>> LoadInventoryMovementsAsync(CancellationToken cancellationToken)
    {
        var itemCosts = await _db.Items
            .AsNoTracking()
            .Where(item => item.ItemType == ItemType.Inventory)
            .ToDictionaryAsync(item => item.Id, item => item.PurchasePrice, cancellationToken);

        var receipts = await _db.InventoryReceipts
            .AsNoTracking()
            .Where(receipt => receipt.Status == InventoryReceiptStatus.Posted)
            .SelectMany(
                receipt => receipt.Lines,
                (receipt, line) => new InventoryMovement(
                    line.ItemId,
                    receipt.ReceiptDate,
                    line.Quantity,
                    line.UnitCost))
            .ToListAsync(cancellationToken);

        var directPurchaseBills = await _db.PurchaseBills
            .AsNoTracking()
            .Where(bill =>
                bill.InventoryReceiptId == null &&
                bill.PostedTransactionId != null &&
                bill.Status != PurchaseBillStatus.Void)
            .SelectMany(
                bill => bill.Lines,
                (bill, line) => new InventoryMovement(
                    line.ItemId,
                    bill.BillDate,
                    line.Quantity,
                    line.UnitCost))
            .ToListAsync(cancellationToken);

        var invoices = await _db.Invoices
            .AsNoTracking()
            .Where(invoice =>
                invoice.PostedTransactionId != null &&
                invoice.Status != Core.Invoices.InvoiceStatus.Void)
            .SelectMany(
                invoice => invoice.Lines,
                (invoice, line) => new
                {
                    invoice.InvoiceDate,
                    line.ItemId,
                    line.Quantity
                })
            .ToListAsync(cancellationToken);

        var invoiceMovements = invoices
            .Select(line => new InventoryMovement(
                line.ItemId,
                line.InvoiceDate,
                -line.Quantity,
                itemCosts.GetValueOrDefault(line.ItemId)))
            .ToList();

        var salesReturns = await _db.SalesReturns
            .AsNoTracking()
            .Where(returnDocument => returnDocument.Status == SalesReturnStatus.Posted)
            .SelectMany(
                returnDocument => returnDocument.Lines,
                (returnDocument, line) => new
                {
                    returnDocument.ReturnDate,
                    line.ItemId,
                    line.Quantity
                })
            .ToListAsync(cancellationToken);

        var salesReturnMovements = salesReturns
            .Select(line => new InventoryMovement(
                line.ItemId,
                line.ReturnDate,
                line.Quantity,
                itemCosts.GetValueOrDefault(line.ItemId)))
            .ToList();

        var purchaseReturns = await _db.PurchaseReturns
            .AsNoTracking()
            .Where(returnDocument => returnDocument.Status == PurchaseReturnStatus.Posted)
            .SelectMany(
                returnDocument => returnDocument.Lines,
                (returnDocument, line) => new InventoryMovement(
                    line.ItemId,
                    returnDocument.ReturnDate,
                    -line.Quantity,
                    line.UnitCost))
            .ToListAsync(cancellationToken);

        var adjustments = await _db.InventoryAdjustments
            .AsNoTracking()
            .Where(adjustment => adjustment.Status == InventoryAdjustmentStatus.Posted)
            .Select(adjustment => new InventoryMovement(
                adjustment.ItemId,
                adjustment.AdjustmentDate,
                adjustment.QuantityChange,
                adjustment.UnitCost))
            .ToListAsync(cancellationToken);

        return
        [
            .. receipts,
            .. directPurchaseBills,
            .. invoiceMovements,
            .. salesReturnMovements,
            .. purchaseReturns,
            .. adjustments
        ];
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

    private sealed record InventoryMovement(
        Guid ItemId,
        DateOnly MovementDate,
        decimal QuantityDelta,
        decimal UnitCost);
}
