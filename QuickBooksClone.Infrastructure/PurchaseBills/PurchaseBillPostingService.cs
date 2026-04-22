using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.ReceiveInventory;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Infrastructure.PurchaseBills;

public sealed class PurchaseBillPostingService : IPurchaseBillPostingService
{
    private const string PurchaseBillSourceEntityType = "PurchaseBill";
    private const string PurchaseBillReversalSourceEntityType = "PurchaseBillReversal";
    private const string GoodsReceivedNotBilledCode = "2050";
    private const string GoodsReceivedNotBilledName = "Inventory Received Not Billed";

    private readonly IPurchaseBillRepository _bills;
    private readonly IInventoryReceiptRepository _receipts;
    private readonly IVendorRepository _vendors;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public PurchaseBillPostingService(
        IPurchaseBillRepository bills,
        IInventoryReceiptRepository receipts,
        IVendorRepository vendors,
        IItemRepository items,
        IAccountRepository accounts,
        IAccountingTransactionRepository transactions)
    {
        _bills = bills;
        _receipts = receipts;
        _vendors = vendors;
        _items = items;
        _accounts = accounts;
        _transactions = transactions;
    }

    public async Task<PurchaseBillPostingResult> PostAsync(Guid purchaseBillId, CancellationToken cancellationToken = default)
    {
        var bill = await _bills.GetByIdAsync(purchaseBillId, cancellationToken);
        if (bill is null)
        {
            return PurchaseBillPostingResult.Failure("Purchase bill does not exist.");
        }

        if (bill.PostedTransactionId is not null)
        {
            return PurchaseBillPostingResult.Success(bill.PostedTransactionId.Value);
        }

        if (bill.Status == PurchaseBillStatus.Void)
        {
            return PurchaseBillPostingResult.Failure("Cannot post a void purchase bill.");
        }

        var existingTransaction = await _transactions.GetBySourceAsync(PurchaseBillSourceEntityType, bill.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            await _bills.MarkPostedAsync(bill.Id, existingTransaction.Id, cancellationToken);
            return PurchaseBillPostingResult.Success(existingTransaction.Id);
        }

        if (bill.Lines.Count == 0)
        {
            return PurchaseBillPostingResult.Failure("Purchase bill must have at least one line.");
        }

        var vendor = await _vendors.GetByIdAsync(bill.VendorId, cancellationToken);
        if (vendor is null)
        {
            return PurchaseBillPostingResult.Failure("Vendor does not exist.");
        }

        if (!vendor.IsActive)
        {
            return PurchaseBillPostingResult.Failure("Cannot post a purchase bill for an inactive vendor.");
        }

        var apAccount = await FindFirstAccountAsync(AccountType.AccountsPayable, cancellationToken);
        if (apAccount is null)
        {
            return PurchaseBillPostingResult.Failure("Accounts Payable account is missing.");
        }

        var grniAccount = await FindGoodsReceivedNotBilledAccountAsync(cancellationToken);
        if (grniAccount is null)
        {
            return PurchaseBillPostingResult.Failure("Inventory Received Not Billed account is missing.");
        }

        InventoryReceipt? linkedReceipt = null;
        Dictionary<Guid, decimal> billedQuantities = [];
        if (bill.InventoryReceiptId is not null)
        {
            linkedReceipt = await _receipts.GetByIdAsync(bill.InventoryReceiptId.Value, cancellationToken);
            if (linkedReceipt is null)
            {
                return PurchaseBillPostingResult.Failure("Linked inventory receipt does not exist.");
            }

            if (linkedReceipt.Status != InventoryReceiptStatus.Posted)
            {
                return PurchaseBillPostingResult.Failure("Linked inventory receipt must be posted before the bill is posted.");
            }

            billedQuantities = await _bills.GetBilledQuantitiesByInventoryReceiptLineIdsAsync(linkedReceipt.Lines.Select(line => line.Id), cancellationToken);
        }

        var lineItems = new List<(PurchaseBillLine Line, Item Item)>();
        foreach (var line in bill.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return PurchaseBillPostingResult.Failure($"Item does not exist: {line.ItemId}");
            }

            if (line.InventoryReceiptLineId is not null)
            {
                if (linkedReceipt is null)
                {
                    return PurchaseBillPostingResult.Failure("Cannot bill inventory receipt lines without a linked inventory receipt.");
                }

                if (item.ItemType != ItemType.Inventory)
                {
                    return PurchaseBillPostingResult.Failure($"Only inventory items can be billed against received inventory. '{item.Name}' is {item.ItemType}.");
                }

                if (item.InventoryAssetAccountId is null)
                {
                    return PurchaseBillPostingResult.Failure($"Inventory item '{item.Name}' is missing an inventory asset account.");
                }

                if (linkedReceipt.Lines.All(receiptLine => receiptLine.Id != line.InventoryReceiptLineId.Value))
                {
                    return PurchaseBillPostingResult.Failure("Purchase bill line references an inventory receipt line that is not on the linked receipt.");
                }

                var receiptLine = linkedReceipt.Lines.First(current => current.Id == line.InventoryReceiptLineId.Value);
                var totalBilledQuantity = billedQuantities.GetValueOrDefault(receiptLine.Id);
                if (totalBilledQuantity > receiptLine.Quantity)
                {
                    return PurchaseBillPostingResult.Failure($"Billed quantity exceeds received quantity for '{item.Name}'. Received: {receiptLine.Quantity:N2}, billed: {totalBilledQuantity:N2}.");
                }
            }
            else if (item.ItemType == ItemType.Inventory)
            {
                if (item.InventoryAssetAccountId is null)
                {
                    return PurchaseBillPostingResult.Failure($"Inventory item '{item.Name}' is missing an inventory asset account.");
                }
            }
            else if (item.ExpenseAccountId is null)
            {
                return PurchaseBillPostingResult.Failure($"Non-inventory/service item '{item.Name}' is missing an expense account.");
            }

            lineItems.Add((line, item));
        }

        var transaction = BuildAccountingTransaction(bill, apAccount.Id, grniAccount.Id, lineItems, linkedReceipt);
        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);

        foreach (var (line, item) in lineItems.Where(current => current.Item.ItemType == ItemType.Inventory && current.Line.InventoryReceiptLineId is null))
        {
            await _items.IncreaseQuantityAsync(item.Id, line.Quantity, cancellationToken);
        }

        await _vendors.ApplyBillAsync(vendor.Id, bill.TotalAmount, cancellationToken);
        await _bills.MarkPostedAsync(bill.Id, savedTransaction.Id, cancellationToken);
        return PurchaseBillPostingResult.Success(savedTransaction.Id);
    }

    public async Task<PurchaseBillPostingResult> VoidAsync(Guid purchaseBillId, CancellationToken cancellationToken = default)
    {
        var bill = await _bills.GetByIdAsync(purchaseBillId, cancellationToken);
        if (bill is null)
        {
            return PurchaseBillPostingResult.Failure("Purchase bill does not exist.");
        }

        if (bill.Status == PurchaseBillStatus.Void)
        {
            return PurchaseBillPostingResult.Success(bill.ReversalTransactionId);
        }

        if (bill.PostedTransactionId is null)
        {
            await _bills.VoidAsync(bill.Id, null, cancellationToken);
            return PurchaseBillPostingResult.Success();
        }

        if (bill.PaidAmount > 0)
        {
            return PurchaseBillPostingResult.Failure("Cannot void a purchase bill with applied payments. Void or reverse the vendor payment first.");
        }

        var vendor = await _vendors.GetByIdAsync(bill.VendorId, cancellationToken);
        if (vendor is null)
        {
            return PurchaseBillPostingResult.Failure("Vendor does not exist.");
        }

        if (bill.TotalAmount > vendor.Balance)
        {
            return PurchaseBillPostingResult.Failure("Purchase bill reversal amount exceeds vendor balance.");
        }

        var existingReversal = await _transactions.GetBySourceAsync(PurchaseBillReversalSourceEntityType, bill.Id, cancellationToken);
        if (existingReversal is not null)
        {
            await _bills.VoidAsync(bill.Id, existingReversal.Id, cancellationToken);
            return PurchaseBillPostingResult.Success(existingReversal.Id);
        }

        var originalTransaction = await _transactions.GetByIdAsync(bill.PostedTransactionId.Value, cancellationToken);
        if (originalTransaction is null)
        {
            return PurchaseBillPostingResult.Failure("Posted purchase bill transaction is missing.");
        }

        var inventoryItems = new List<(PurchaseBillLine Line, Item Item)>();
        foreach (var line in bill.Lines)
        {
            if (line.InventoryReceiptLineId is not null)
            {
                continue;
            }

            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return PurchaseBillPostingResult.Failure($"Item does not exist: {line.ItemId}");
            }

            if (item.ItemType != ItemType.Inventory)
            {
                continue;
            }

            if (item.QuantityOnHand < line.Quantity)
            {
                return PurchaseBillPostingResult.Failure($"Cannot void purchase bill because '{item.Name}' has only {item.QuantityOnHand:N2} on hand, but {line.Quantity:N2} must be removed.");
            }

            inventoryItems.Add((line, item));
        }

        var reversalTransaction = BuildReversalTransaction(bill, originalTransaction);
        var savedReversal = await _transactions.AddAsync(reversalTransaction, cancellationToken);

        foreach (var (line, item) in inventoryItems)
        {
            await _items.DecreaseQuantityAsync(item.Id, line.Quantity, cancellationToken);
        }

        await _vendors.ReverseBillAsync(vendor.Id, bill.TotalAmount, cancellationToken);
        await _bills.VoidAsync(bill.Id, savedReversal.Id, cancellationToken);
        return PurchaseBillPostingResult.Success(savedReversal.Id);
    }

    private static AccountingTransaction BuildAccountingTransaction(
        PurchaseBill bill,
        Guid accountsPayableAccountId,
        Guid goodsReceivedNotBilledAccountId,
        IReadOnlyList<(PurchaseBillLine Line, Item Item)> lineItems,
        InventoryReceipt? linkedReceipt)
    {
        var transaction = new AccountingTransaction(
            "PurchaseBill",
            bill.BillDate,
            bill.BillNumber,
            PurchaseBillSourceEntityType,
            bill.Id);

        foreach (var (line, item) in lineItems)
        {
            if (line.InventoryReceiptLineId is not null)
            {
                var receiptLine = linkedReceipt!.Lines.First(current => current.Id == line.InventoryReceiptLineId.Value);
                var receiptAmount = receiptLine.UnitCost * line.Quantity;
                transaction.AddLine(new AccountingTransactionLine(
                    goodsReceivedNotBilledAccountId,
                    $"Clear GRNI {receiptLine.Description}",
                    receiptAmount,
                    0));

                var variance = line.LineTotal - receiptAmount;
                if (variance > 0)
                {
                    transaction.AddLine(new AccountingTransactionLine(
                        item.InventoryAssetAccountId!.Value,
                        $"Receipt cost variance {line.Description}",
                        variance,
                        0));
                }
                else if (variance < 0)
                {
                    transaction.AddLine(new AccountingTransactionLine(
                        item.InventoryAssetAccountId!.Value,
                        $"Receipt cost variance {line.Description}",
                        0,
                        Math.Abs(variance)));
                }

                continue;
            }

            var debitAccountId = item.ItemType == ItemType.Inventory
                ? item.InventoryAssetAccountId!.Value
                : item.ExpenseAccountId!.Value;

            transaction.AddLine(new AccountingTransactionLine(
                debitAccountId,
                line.Description,
                line.LineTotal,
                0));
        }

        transaction.AddLine(new AccountingTransactionLine(
            accountsPayableAccountId,
            $"Purchase bill {bill.BillNumber}",
            0,
            bill.TotalAmount));

        return transaction;
    }

    private static AccountingTransaction BuildReversalTransaction(
        PurchaseBill bill,
        AccountingTransaction originalTransaction)
    {
        var transaction = new AccountingTransaction(
            "PurchaseBillReversal",
            DateOnly.FromDateTime(DateTime.UtcNow),
            $"{bill.BillNumber}-VOID",
            PurchaseBillReversalSourceEntityType,
            bill.Id);

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

    private async Task<Account?> FindFirstAccountAsync(AccountType accountType, CancellationToken cancellationToken)
    {
        var result = await _accounts.SearchAsync(new AccountSearch(null, accountType, false, 1, 1), cancellationToken);
        return result.Items.FirstOrDefault();
    }

    private async Task<Account?> FindGoodsReceivedNotBilledAccountAsync(CancellationToken cancellationToken)
    {
        var result = await _accounts.SearchAsync(new AccountSearch(null, AccountType.OtherCurrentLiability, false, 1, 50), cancellationToken);
        return result.Items.FirstOrDefault(account =>
            string.Equals(account.Code, GoodsReceivedNotBilledCode, StringComparison.OrdinalIgnoreCase) ||
            string.Equals(account.Name, GoodsReceivedNotBilledName, StringComparison.OrdinalIgnoreCase));
    }
}
