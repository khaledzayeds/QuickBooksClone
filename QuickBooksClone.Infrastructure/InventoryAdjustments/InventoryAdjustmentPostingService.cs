using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.InventoryAdjustments;
using QuickBooksClone.Core.Items;

namespace QuickBooksClone.Infrastructure.InventoryAdjustments;

public sealed class InventoryAdjustmentPostingService : IInventoryAdjustmentPostingService
{
    private const string InventoryAdjustmentSourceEntityType = "InventoryAdjustment";

    private readonly IInventoryAdjustmentRepository _adjustments;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public InventoryAdjustmentPostingService(IInventoryAdjustmentRepository adjustments, IItemRepository items, IAccountRepository accounts, IAccountingTransactionRepository transactions)
    {
        _adjustments = adjustments;
        _items = items;
        _accounts = accounts;
        _transactions = transactions;
    }

    public async Task<InventoryAdjustmentPostingResult> PostAsync(Guid adjustmentId, CancellationToken cancellationToken = default)
    {
        var adjustment = await _adjustments.GetByIdAsync(adjustmentId, cancellationToken);
        if (adjustment is null) return InventoryAdjustmentPostingResult.Failure("Inventory adjustment does not exist.");
        if (adjustment.Status == InventoryAdjustmentStatus.Void) return InventoryAdjustmentPostingResult.Failure("Cannot post a void inventory adjustment.");
        if (adjustment.PostedTransactionId is not null) return InventoryAdjustmentPostingResult.Success(adjustment.PostedTransactionId.Value);

        var existingTransaction = await _transactions.GetBySourceAsync(InventoryAdjustmentSourceEntityType, adjustment.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            await _adjustments.MarkPostedAsync(adjustment.Id, existingTransaction.Id, cancellationToken);
            return InventoryAdjustmentPostingResult.Success(existingTransaction.Id);
        }

        var item = await _items.GetByIdAsync(adjustment.ItemId, cancellationToken);
        if (item is null) return InventoryAdjustmentPostingResult.Failure("Item does not exist.");
        if (item.ItemType != ItemType.Inventory) return InventoryAdjustmentPostingResult.Failure("Only inventory items can be adjusted.");
        if (item.InventoryAssetAccountId is null) return InventoryAdjustmentPostingResult.Failure($"Inventory item '{item.Name}' is missing an inventory asset account.");
        if (adjustment.QuantityChange < 0 && item.QuantityOnHand < Math.Abs(adjustment.QuantityChange))
        {
            return InventoryAdjustmentPostingResult.Failure($"Cannot decrease '{item.Name}' below zero. On hand: {item.QuantityOnHand:N2}, decrease: {Math.Abs(adjustment.QuantityChange):N2}.");
        }

        var adjustmentAccount = await _accounts.GetByIdAsync(adjustment.AdjustmentAccountId, cancellationToken);
        if (adjustmentAccount is null) return InventoryAdjustmentPostingResult.Failure("Adjustment account does not exist.");
        if (adjustmentAccount.AccountType is not AccountType.Expense and not AccountType.CostOfGoodsSold and not AccountType.OtherExpense and not AccountType.Income and not AccountType.OtherIncome)
        {
            return InventoryAdjustmentPostingResult.Failure("Adjustment account must be an income, other income, expense, other expense, or COGS account.");
        }

        var transaction = BuildAccountingTransaction(adjustment, item.InventoryAssetAccountId.Value);
        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);

        if (adjustment.QuantityChange > 0)
        {
            await _items.IncreaseQuantityAsync(item.Id, adjustment.QuantityChange, cancellationToken);
        }
        else
        {
            await _items.DecreaseQuantityAsync(item.Id, Math.Abs(adjustment.QuantityChange), cancellationToken);
        }

        await _adjustments.MarkPostedAsync(adjustment.Id, savedTransaction.Id, cancellationToken);
        return InventoryAdjustmentPostingResult.Success(savedTransaction.Id);
    }

    private static AccountingTransaction BuildAccountingTransaction(InventoryAdjustment adjustment, Guid inventoryAssetAccountId)
    {
        var transaction = new AccountingTransaction("InventoryAdjustment", adjustment.AdjustmentDate, adjustment.AdjustmentNumber, InventoryAdjustmentSourceEntityType, adjustment.Id);
        if (adjustment.QuantityChange > 0)
        {
            transaction.AddLine(new AccountingTransactionLine(inventoryAssetAccountId, adjustment.Reason, adjustment.TotalCost, 0));
            transaction.AddLine(new AccountingTransactionLine(adjustment.AdjustmentAccountId, adjustment.Reason, 0, adjustment.TotalCost));
        }
        else
        {
            transaction.AddLine(new AccountingTransactionLine(adjustment.AdjustmentAccountId, adjustment.Reason, adjustment.TotalCost, 0));
            transaction.AddLine(new AccountingTransactionLine(inventoryAssetAccountId, adjustment.Reason, 0, adjustment.TotalCost));
        }

        return transaction;
    }
}
