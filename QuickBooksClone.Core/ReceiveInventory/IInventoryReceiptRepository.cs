namespace QuickBooksClone.Core.ReceiveInventory;

public interface IInventoryReceiptRepository
{
    Task<InventoryReceiptListResult> SearchAsync(InventoryReceiptSearch search, CancellationToken cancellationToken = default);
    Task<InventoryReceipt?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<InventoryReceipt> AddAsync(InventoryReceipt receipt, CancellationToken cancellationToken = default);
    Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default);
    Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default);
    Task<Dictionary<Guid, decimal>> GetReceivedQuantitiesByPurchaseOrderLineIdsAsync(IEnumerable<Guid> purchaseOrderLineIds, CancellationToken cancellationToken = default);
}
