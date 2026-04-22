using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.ReceiveInventory;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Infrastructure.ReceiveInventory;

public sealed class InventoryReceiptPostingService : IInventoryReceiptPostingService
{
    private const string InventoryReceiptSourceEntityType = "InventoryReceipt";
    private const string InventoryReceiptReversalSourceEntityType = "InventoryReceiptReversal";
    private const string GoodsReceivedNotBilledCode = "2050";
    private const string GoodsReceivedNotBilledName = "Inventory Received Not Billed";

    private readonly IInventoryReceiptRepository _receipts;
    private readonly IVendorRepository _vendors;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public InventoryReceiptPostingService(
        IInventoryReceiptRepository receipts,
        IVendorRepository vendors,
        IItemRepository items,
        IAccountRepository accounts,
        IAccountingTransactionRepository transactions)
    {
        _receipts = receipts;
        _vendors = vendors;
        _items = items;
        _accounts = accounts;
        _transactions = transactions;
    }

    public async Task<InventoryReceiptPostingResult> PostAsync(Guid receiptId, CancellationToken cancellationToken = default)
    {
        var receipt = await _receipts.GetByIdAsync(receiptId, cancellationToken);
        if (receipt is null)
        {
            return InventoryReceiptPostingResult.Failure("Inventory receipt does not exist.");
        }

        if (receipt.PostedTransactionId is not null)
        {
            return InventoryReceiptPostingResult.Success(receipt.PostedTransactionId.Value);
        }

        if (receipt.Status == InventoryReceiptStatus.Void)
        {
            return InventoryReceiptPostingResult.Failure("Cannot post a void inventory receipt.");
        }

        var existingTransaction = await _transactions.GetBySourceAsync(InventoryReceiptSourceEntityType, receipt.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            await _receipts.MarkPostedAsync(receipt.Id, existingTransaction.Id, cancellationToken);
            return InventoryReceiptPostingResult.Success(existingTransaction.Id);
        }

        if (receipt.Lines.Count == 0)
        {
            return InventoryReceiptPostingResult.Failure("Inventory receipt must have at least one line.");
        }

        var vendor = await _vendors.GetByIdAsync(receipt.VendorId, cancellationToken);
        if (vendor is null)
        {
            return InventoryReceiptPostingResult.Failure("Vendor does not exist.");
        }

        if (!vendor.IsActive)
        {
            return InventoryReceiptPostingResult.Failure("Cannot receive inventory for an inactive vendor.");
        }

        var grniAccount = await FindGoodsReceivedNotBilledAccountAsync(cancellationToken);
        if (grniAccount is null)
        {
            return InventoryReceiptPostingResult.Failure("Inventory Received Not Billed account is missing.");
        }

        var lineItems = new List<(InventoryReceiptLine Line, Item Item)>();
        foreach (var line in receipt.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return InventoryReceiptPostingResult.Failure($"Item does not exist: {line.ItemId}");
            }

            if (item.ItemType != ItemType.Inventory)
            {
                return InventoryReceiptPostingResult.Failure($"Receive Inventory only supports inventory items. '{item.Name}' is {item.ItemType}.");
            }

            if (item.InventoryAssetAccountId is null)
            {
                return InventoryReceiptPostingResult.Failure($"Inventory item '{item.Name}' is missing an inventory asset account.");
            }

            lineItems.Add((line, item));
        }

        var transaction = BuildAccountingTransaction(receipt, grniAccount.Id, lineItems);
        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);

        foreach (var (line, item) in lineItems)
        {
            await _items.IncreaseQuantityAsync(item.Id, line.Quantity, cancellationToken);
        }

        await _receipts.MarkPostedAsync(receipt.Id, savedTransaction.Id, cancellationToken);
        return InventoryReceiptPostingResult.Success(savedTransaction.Id);
    }

    public async Task<InventoryReceiptPostingResult> VoidAsync(Guid receiptId, CancellationToken cancellationToken = default)
    {
        var receipt = await _receipts.GetByIdAsync(receiptId, cancellationToken);
        if (receipt is null)
        {
            return InventoryReceiptPostingResult.Failure("Inventory receipt does not exist.");
        }

        if (receipt.Status == InventoryReceiptStatus.Void)
        {
            return InventoryReceiptPostingResult.Success(receipt.ReversalTransactionId);
        }

        if (receipt.PostedTransactionId is null)
        {
            await _receipts.VoidAsync(receipt.Id, null, cancellationToken);
            return InventoryReceiptPostingResult.Success();
        }

        var existingReversal = await _transactions.GetBySourceAsync(InventoryReceiptReversalSourceEntityType, receipt.Id, cancellationToken);
        if (existingReversal is not null)
        {
            await _receipts.VoidAsync(receipt.Id, existingReversal.Id, cancellationToken);
            return InventoryReceiptPostingResult.Success(existingReversal.Id);
        }

        var originalTransaction = await _transactions.GetByIdAsync(receipt.PostedTransactionId.Value, cancellationToken);
        if (originalTransaction is null)
        {
            return InventoryReceiptPostingResult.Failure("Posted inventory receipt transaction is missing.");
        }

        var inventoryItems = new List<(InventoryReceiptLine Line, Item Item)>();
        foreach (var line in receipt.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return InventoryReceiptPostingResult.Failure($"Item does not exist: {line.ItemId}");
            }

            if (item.QuantityOnHand < line.Quantity)
            {
                return InventoryReceiptPostingResult.Failure($"Cannot void inventory receipt because '{item.Name}' has only {item.QuantityOnHand:N2} on hand, but {line.Quantity:N2} must be removed.");
            }

            inventoryItems.Add((line, item));
        }

        var reversalTransaction = BuildReversalTransaction(receipt, originalTransaction);
        var savedReversal = await _transactions.AddAsync(reversalTransaction, cancellationToken);

        foreach (var (line, item) in inventoryItems)
        {
            await _items.DecreaseQuantityAsync(item.Id, line.Quantity, cancellationToken);
        }

        await _receipts.VoidAsync(receipt.Id, savedReversal.Id, cancellationToken);
        return InventoryReceiptPostingResult.Success(savedReversal.Id);
    }

    private static AccountingTransaction BuildAccountingTransaction(
        InventoryReceipt receipt,
        Guid grniAccountId,
        IReadOnlyList<(InventoryReceiptLine Line, Item Item)> lineItems)
    {
        var transaction = new AccountingTransaction(
            "InventoryReceipt",
            receipt.ReceiptDate,
            receipt.ReceiptNumber,
            InventoryReceiptSourceEntityType,
            receipt.Id);

        foreach (var (line, item) in lineItems)
        {
            transaction.AddLine(new AccountingTransactionLine(
                item.InventoryAssetAccountId!.Value,
                line.Description,
                line.LineTotal,
                0));
        }

        transaction.AddLine(new AccountingTransactionLine(
            grniAccountId,
            $"Inventory received not billed {receipt.ReceiptNumber}",
            0,
            receipt.TotalAmount));

        return transaction;
    }

    private static AccountingTransaction BuildReversalTransaction(
        InventoryReceipt receipt,
        AccountingTransaction originalTransaction)
    {
        var transaction = new AccountingTransaction(
            "InventoryReceiptReversal",
            DateOnly.FromDateTime(DateTime.UtcNow),
            $"{receipt.ReceiptNumber}-VOID",
            InventoryReceiptReversalSourceEntityType,
            receipt.Id);

        foreach (var line in originalTransaction.Lines)
        {
            transaction.AddLine(new AccountingTransactionLine(
                line.AccountId,
                $"Reversal - {line.Description}",
                line.Credit,
                line.Debit));
        }

        return transaction;
    }

    private async Task<Account?> FindGoodsReceivedNotBilledAccountAsync(CancellationToken cancellationToken)
    {
        var result = await _accounts.SearchAsync(new AccountSearch(null, AccountType.OtherCurrentLiability, false, 1, 50), cancellationToken);
        return result.Items.FirstOrDefault(account =>
            string.Equals(account.Code, GoodsReceivedNotBilledCode, StringComparison.OrdinalIgnoreCase) ||
            string.Equals(account.Name, GoodsReceivedNotBilledName, StringComparison.OrdinalIgnoreCase));
    }
}
