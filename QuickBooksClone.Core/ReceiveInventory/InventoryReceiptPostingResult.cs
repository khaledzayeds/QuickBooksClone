namespace QuickBooksClone.Core.ReceiveInventory;

public sealed record InventoryReceiptPostingResult(bool Succeeded, Guid? TransactionId = null, string? ErrorMessage = null)
{
    public static InventoryReceiptPostingResult Success(Guid? transactionId = null) => new(true, transactionId, null);
    public static InventoryReceiptPostingResult Failure(string message) => new(false, null, message);
}
