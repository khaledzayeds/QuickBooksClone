namespace QuickBooksClone.Core.InventoryAdjustments;

public sealed record InventoryAdjustmentPostingResult(bool Succeeded, Guid? TransactionId, string? ErrorMessage)
{
    public static InventoryAdjustmentPostingResult Success(Guid? transactionId = null) => new(true, transactionId, null);
    public static InventoryAdjustmentPostingResult Failure(string errorMessage) => new(false, null, errorMessage);
}
