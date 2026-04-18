using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.OpeningBalances;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Infrastructure.OpeningBalances;

public sealed class OpeningBalancePostingService : IOpeningBalancePostingService
{
    private const string CustomerOpeningSourceEntityType = "CustomerOpeningBalance";
    private const string VendorOpeningSourceEntityType = "VendorOpeningBalance";
    private const string ItemOpeningSourceEntityType = "ItemOpeningBalance";

    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public OpeningBalancePostingService(
        IAccountRepository accounts,
        IAccountingTransactionRepository transactions)
    {
        _accounts = accounts;
        _transactions = transactions;
    }

    public async Task<OpeningBalancePostingResult> PostCustomerOpeningBalanceAsync(Customer customer, CancellationToken cancellationToken = default)
    {
        if (customer.Balance <= 0)
        {
            return OpeningBalancePostingResult.Success();
        }

        var existingTransaction = await _transactions.GetBySourceAsync(CustomerOpeningSourceEntityType, customer.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            return OpeningBalancePostingResult.Success(existingTransaction.Id);
        }

        var arAccount = await FindFirstAccountAsync(AccountType.AccountsReceivable, cancellationToken);
        if (arAccount is null)
        {
            return OpeningBalancePostingResult.Failure("Accounts Receivable account is missing.");
        }

        var equityAccount = await FindFirstAccountAsync(AccountType.Equity, cancellationToken);
        if (equityAccount is null)
        {
            return OpeningBalancePostingResult.Failure("Opening equity account is missing.");
        }

        var transaction = new AccountingTransaction(
            "OpeningBalance",
            DateOnly.FromDateTime(DateTime.UtcNow),
            $"OPEN-CUST-{customer.Id.ToString()[..8]}",
            CustomerOpeningSourceEntityType,
            customer.Id);

        transaction.AddLine(new AccountingTransactionLine(
            arAccount.Id,
            $"Opening balance - {customer.DisplayName}",
            customer.Balance,
            0));

        transaction.AddLine(new AccountingTransactionLine(
            equityAccount.Id,
            $"Opening balance offset - {customer.DisplayName}",
            0,
            customer.Balance));

        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);
        return OpeningBalancePostingResult.Success(savedTransaction.Id);
    }

    public async Task<OpeningBalancePostingResult> PostVendorOpeningBalanceAsync(Vendor vendor, CancellationToken cancellationToken = default)
    {
        if (vendor.Balance <= 0)
        {
            return OpeningBalancePostingResult.Success();
        }

        var existingTransaction = await _transactions.GetBySourceAsync(VendorOpeningSourceEntityType, vendor.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            return OpeningBalancePostingResult.Success(existingTransaction.Id);
        }

        var apAccount = await FindFirstAccountAsync(AccountType.AccountsPayable, cancellationToken);
        if (apAccount is null)
        {
            return OpeningBalancePostingResult.Failure("Accounts Payable account is missing.");
        }

        var equityAccount = await FindFirstAccountAsync(AccountType.Equity, cancellationToken);
        if (equityAccount is null)
        {
            return OpeningBalancePostingResult.Failure("Opening equity account is missing.");
        }

        var transaction = new AccountingTransaction(
            "OpeningBalance",
            DateOnly.FromDateTime(DateTime.UtcNow),
            $"OPEN-VEND-{vendor.Id.ToString()[..8]}",
            VendorOpeningSourceEntityType,
            vendor.Id);

        transaction.AddLine(new AccountingTransactionLine(
            equityAccount.Id,
            $"Opening balance offset - {vendor.DisplayName}",
            vendor.Balance,
            0));

        transaction.AddLine(new AccountingTransactionLine(
            apAccount.Id,
            $"Opening balance - {vendor.DisplayName}",
            0,
            vendor.Balance));

        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);
        return OpeningBalancePostingResult.Success(savedTransaction.Id);
    }

    public async Task<OpeningBalancePostingResult> PostItemOpeningBalanceAsync(Item item, CancellationToken cancellationToken = default)
    {
        if (item.ItemType != ItemType.Inventory || item.QuantityOnHand <= 0 || item.PurchasePrice <= 0)
        {
            return OpeningBalancePostingResult.Success();
        }

        var existingTransaction = await _transactions.GetBySourceAsync(ItemOpeningSourceEntityType, item.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            return OpeningBalancePostingResult.Success(existingTransaction.Id);
        }

        if (item.InventoryAssetAccountId is null)
        {
            return OpeningBalancePostingResult.Failure($"Inventory item '{item.Name}' is missing an inventory asset account.");
        }

        var inventoryAccount = await _accounts.GetByIdAsync(item.InventoryAssetAccountId.Value, cancellationToken);
        if (inventoryAccount is null)
        {
            return OpeningBalancePostingResult.Failure("Inventory asset account does not exist.");
        }

        var equityAccount = await FindFirstAccountAsync(AccountType.Equity, cancellationToken);
        if (equityAccount is null)
        {
            return OpeningBalancePostingResult.Failure("Opening equity account is missing.");
        }

        var amount = item.QuantityOnHand * item.PurchasePrice;
        var transaction = new AccountingTransaction(
            "OpeningBalance",
            DateOnly.FromDateTime(DateTime.UtcNow),
            $"OPEN-ITEM-{item.Id.ToString()[..8]}",
            ItemOpeningSourceEntityType,
            item.Id);

        transaction.AddLine(new AccountingTransactionLine(
            inventoryAccount.Id,
            $"Opening inventory - {item.Name}",
            amount,
            0));

        transaction.AddLine(new AccountingTransactionLine(
            equityAccount.Id,
            $"Opening inventory offset - {item.Name}",
            0,
            amount));

        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);
        return OpeningBalancePostingResult.Success(savedTransaction.Id);
    }

    private async Task<Account?> FindFirstAccountAsync(AccountType accountType, CancellationToken cancellationToken)
    {
        var result = await _accounts.SearchAsync(new AccountSearch(null, accountType, false, 1, 1), cancellationToken);
        return result.Items.FirstOrDefault();
    }
}
