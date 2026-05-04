using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Infrastructure.Accounting;

public sealed class DefaultAccountsSeeder : IDefaultAccountsSeeder
{
    private readonly IAccountRepository _accounts;

    public DefaultAccountsSeeder(IAccountRepository accounts)
    {
        _accounts = accounts;
    }

    public async Task<DefaultAccountsSeedResult> SeedAsync(CancellationToken cancellationToken = default)
    {
        var createdCodes = new List<string>();
        var skippedCodes = new List<string>();

        foreach (var definition in Definitions)
        {
            if (await _accounts.CodeExistsAsync(definition.Code, excludingId: null, cancellationToken))
            {
                skippedCodes.Add(definition.Code);
                continue;
            }

            var account = new Account(
                definition.Code,
                definition.Name,
                definition.AccountType,
                definition.Description);

            await _accounts.AddAsync(account, cancellationToken);
            createdCodes.Add(definition.Code);
        }

        return new DefaultAccountsSeedResult(
            createdCodes.Count,
            skippedCodes.Count,
            createdCodes,
            skippedCodes);
    }

    public static IReadOnlyList<DefaultAccountDefinition> Definitions { get; } = new List<DefaultAccountDefinition>
    {
        new("1000", "Cash on Hand", AccountType.Bank, "Default cash drawer / petty cash account."),
        new("1010", "Main Bank Account", AccountType.Bank, "Primary operating bank account."),
        new("1100", "Accounts Receivable", AccountType.AccountsReceivable, "Customer balances from invoices."),
        new("1200", "Inventory Asset", AccountType.InventoryAsset, "Inventory item value on hand."),
        new("1300", "Undeposited Funds", AccountType.OtherCurrentAsset, "Temporary holding account for received payments before deposit."),
        new("1500", "Fixed Assets", AccountType.FixedAsset, "Property, equipment, and long-term assets."),

        new("2000", "Accounts Payable", AccountType.AccountsPayable, "Vendor balances from bills."),
        new("2100", "VAT / Sales Tax Payable", AccountType.OtherCurrentLiability, "Collected output tax waiting to be paid."),
        new("2110", "Input VAT Recoverable", AccountType.OtherCurrentAsset, "Input tax paid to vendors and recoverable."),
        new("2200", "Customer Deposits", AccountType.OtherCurrentLiability, "Customer advances and deposits."),
        new("2300", "Credit Card Payable", AccountType.CreditCard, "Credit card liability account."),
        new("2500", "Loans Payable", AccountType.LongTermLiability, "Long-term financing and loans."),

        new("3000", "Owner Capital", AccountType.Equity, "Owner contributions and capital."),
        new("3100", "Owner Drawings", AccountType.Equity, "Owner withdrawals."),
        new("3200", "Retained Earnings", AccountType.Equity, "Accumulated retained earnings."),
        new("3300", "Opening Balance Equity", AccountType.Equity, "Temporary account for opening balances."),

        new("4000", "Sales Income", AccountType.Income, "Default income account for product and service sales."),
        new("4010", "Sales Discounts", AccountType.Income, "Discounts given on sales."),
        new("4020", "Sales Returns and Allowances", AccountType.Income, "Contra-sales account for returns and allowances."),
        new("4100", "Service Income", AccountType.Income, "Default income account for services."),
        new("4200", "Other Income", AccountType.OtherIncome, "Miscellaneous income."),

        new("5000", "Cost of Goods Sold", AccountType.CostOfGoodsSold, "Default COGS account for sold inventory."),
        new("5010", "Purchase Price Variance", AccountType.CostOfGoodsSold, "Inventory purchase price differences."),
        new("5020", "Inventory Adjustments", AccountType.CostOfGoodsSold, "Shrinkage and inventory adjustment expense."),
        new("5100", "Shipping and Freight In", AccountType.CostOfGoodsSold, "Inbound shipping and freight costs."),

        new("6000", "General Expenses", AccountType.Expense, "General operating expenses."),
        new("6010", "Rent Expense", AccountType.Expense, "Office or store rent."),
        new("6020", "Utilities Expense", AccountType.Expense, "Electricity, water, internet, and utilities."),
        new("6030", "Salaries and Wages", AccountType.Expense, "Payroll and wages expense."),
        new("6040", "Marketing Expense", AccountType.Expense, "Advertising and marketing costs."),
        new("6050", "Bank Fees", AccountType.Expense, "Bank charges and payment processing fees."),
        new("6060", "Office Supplies", AccountType.Expense, "Office and consumable supplies."),
        new("6070", "Repairs and Maintenance", AccountType.Expense, "Repairs and maintenance costs."),
        new("6900", "Other Expense", AccountType.OtherExpense, "Miscellaneous other expenses."),
    };
}
