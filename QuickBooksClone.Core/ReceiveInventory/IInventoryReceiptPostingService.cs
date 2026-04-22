namespace QuickBooksClone.Core.ReceiveInventory;

public interface IInventoryReceiptPostingService
{
    Task<InventoryReceiptPostingResult> PostAsync(Guid receiptId, CancellationToken cancellationToken = default);
    Task<InventoryReceiptPostingResult> VoidAsync(Guid receiptId, CancellationToken cancellationToken = default);
}
