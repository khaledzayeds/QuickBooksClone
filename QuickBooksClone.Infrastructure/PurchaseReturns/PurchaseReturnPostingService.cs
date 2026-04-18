using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.PurchaseReturns;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Infrastructure.PurchaseReturns;

public sealed class PurchaseReturnPostingService : IPurchaseReturnPostingService
{
    private const string PurchaseReturnSourceEntityType = "PurchaseReturn";

    private readonly IPurchaseReturnRepository _returns;
    private readonly IPurchaseBillRepository _bills;
    private readonly IVendorRepository _vendors;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public PurchaseReturnPostingService(IPurchaseReturnRepository returns, IPurchaseBillRepository bills, IVendorRepository vendors, IItemRepository items, IAccountRepository accounts, IAccountingTransactionRepository transactions)
    {
        _returns = returns;
        _bills = bills;
        _vendors = vendors;
        _items = items;
        _accounts = accounts;
        _transactions = transactions;
    }

    public async Task<PurchaseReturnPostingResult> PostAsync(Guid purchaseReturnId, CancellationToken cancellationToken = default)
    {
        var purchaseReturn = await _returns.GetByIdAsync(purchaseReturnId, cancellationToken);
        if (purchaseReturn is null) return PurchaseReturnPostingResult.Failure("Purchase return does not exist.");
        if (purchaseReturn.Status == PurchaseReturnStatus.Void) return PurchaseReturnPostingResult.Failure("Cannot post a void purchase return.");
        if (purchaseReturn.PostedTransactionId is not null) return PurchaseReturnPostingResult.Success(purchaseReturn.PostedTransactionId.Value);

        var existingTransaction = await _transactions.GetBySourceAsync(PurchaseReturnSourceEntityType, purchaseReturn.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            await _returns.MarkPostedAsync(purchaseReturn.Id, existingTransaction.Id, cancellationToken);
            return PurchaseReturnPostingResult.Success(existingTransaction.Id);
        }

        var bill = await _bills.GetByIdAsync(purchaseReturn.PurchaseBillId, cancellationToken);
        if (bill is null) return PurchaseReturnPostingResult.Failure("Purchase bill does not exist.");
        if (bill.Status is PurchaseBillStatus.Draft or PurchaseBillStatus.Void) return PurchaseReturnPostingResult.Failure("Cannot return a draft or void purchase bill.");
        if (bill.VendorId != purchaseReturn.VendorId) return PurchaseReturnPostingResult.Failure("Purchase return vendor does not match purchase bill vendor.");
        if (purchaseReturn.Lines.Count == 0) return PurchaseReturnPostingResult.Failure("Purchase return must have at least one line.");

        var apAccount = await FindFirstAccountAsync(AccountType.AccountsPayable, cancellationToken);
        if (apAccount is null) return PurchaseReturnPostingResult.Failure("Accounts Payable account is missing.");

        var returnedQuantities = await GetPostedReturnedQuantitiesAsync(purchaseReturn, cancellationToken);
        var lines = new List<(PurchaseReturnLine ReturnLine, PurchaseBillLine BillLine, Item Item)>();
        foreach (var returnLine in purchaseReturn.Lines)
        {
            var billLine = bill.Lines.FirstOrDefault(line => line.Id == returnLine.PurchaseBillLineId);
            if (billLine is null) return PurchaseReturnPostingResult.Failure($"Purchase bill line does not exist: {returnLine.PurchaseBillLineId}");
            if (billLine.ItemId != returnLine.ItemId) return PurchaseReturnPostingResult.Failure("Returned item does not match purchase bill line item.");
            var alreadyReturned = returnedQuantities.GetValueOrDefault(billLine.Id);
            if (alreadyReturned + returnLine.Quantity > billLine.Quantity)
            {
                return PurchaseReturnPostingResult.Failure($"Return quantity for '{billLine.Description}' exceeds purchased quantity. Available to return: {billLine.Quantity - alreadyReturned:N2}.");
            }

            var item = await _items.GetByIdAsync(returnLine.ItemId, cancellationToken);
            if (item is null) return PurchaseReturnPostingResult.Failure($"Item does not exist: {returnLine.ItemId}");
            if (item.ItemType == ItemType.Inventory)
            {
                if (item.InventoryAssetAccountId is null) return PurchaseReturnPostingResult.Failure($"Inventory item '{item.Name}' is missing an inventory asset account.");
                if (item.QuantityOnHand < returnLine.Quantity) return PurchaseReturnPostingResult.Failure($"Cannot return '{item.Name}' because stock on hand is {item.QuantityOnHand:N2}, required {returnLine.Quantity:N2}.");
            }
            else if (item.ExpenseAccountId is null)
            {
                return PurchaseReturnPostingResult.Failure($"Non-inventory/service item '{item.Name}' is missing an expense account.");
            }

            lines.Add((returnLine, billLine, item));
        }

        var transaction = BuildAccountingTransaction(purchaseReturn, apAccount.Id, lines);
        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);

        foreach (var (returnLine, _, item) in lines.Where(current => current.Item.ItemType == ItemType.Inventory))
        {
            await _items.DecreaseQuantityAsync(item.Id, returnLine.Quantity, cancellationToken);
        }

        await _bills.ApplyReturnAsync(bill.Id, purchaseReturn.TotalAmount, cancellationToken);
        await _vendors.ApplyPurchaseReturnAsync(bill.VendorId, purchaseReturn.TotalAmount, cancellationToken);
        await _returns.MarkPostedAsync(purchaseReturn.Id, savedTransaction.Id, cancellationToken);
        return PurchaseReturnPostingResult.Success(savedTransaction.Id);
    }

    private async Task<Dictionary<Guid, decimal>> GetPostedReturnedQuantitiesAsync(PurchaseReturn currentReturn, CancellationToken cancellationToken)
    {
        var result = await _returns.SearchAsync(new PurchaseReturnSearch(PurchaseBillId: currentReturn.PurchaseBillId, IncludeVoid: false, PageSize: 200), cancellationToken);
        return result.Items
            .Where(item => item.Id != currentReturn.Id && item.Status == PurchaseReturnStatus.Posted)
            .SelectMany(item => item.Lines)
            .GroupBy(line => line.PurchaseBillLineId)
            .ToDictionary(group => group.Key, group => group.Sum(line => line.Quantity));
    }

    private static AccountingTransaction BuildAccountingTransaction(PurchaseReturn purchaseReturn, Guid accountsPayableAccountId, IReadOnlyList<(PurchaseReturnLine ReturnLine, PurchaseBillLine BillLine, Item Item)> lines)
    {
        var transaction = new AccountingTransaction("PurchaseReturn", purchaseReturn.ReturnDate, purchaseReturn.ReturnNumber, PurchaseReturnSourceEntityType, purchaseReturn.Id);
        transaction.AddLine(new AccountingTransactionLine(accountsPayableAccountId, $"Purchase return {purchaseReturn.ReturnNumber}", purchaseReturn.TotalAmount, 0));
        foreach (var (returnLine, _, item) in lines)
        {
            var creditAccountId = item.ItemType == ItemType.Inventory ? item.InventoryAssetAccountId!.Value : item.ExpenseAccountId!.Value;
            transaction.AddLine(new AccountingTransactionLine(creditAccountId, $"Return - {returnLine.Description}", 0, returnLine.LineTotal));
        }

        return transaction;
    }

    private async Task<Account?> FindFirstAccountAsync(AccountType accountType, CancellationToken cancellationToken)
    {
        var result = await _accounts.SearchAsync(new AccountSearch(null, accountType, false, 1, 1), cancellationToken);
        return result.Items.FirstOrDefault();
    }
}
