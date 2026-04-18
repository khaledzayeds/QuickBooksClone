namespace QuickBooksClone.Core.InventoryAdjustments;

public interface IInventoryAdjustmentRepository
{
    Task<InventoryAdjustmentListResult> SearchAsync(InventoryAdjustmentSearch search, CancellationToken cancellationToken = default);
    Task<InventoryAdjustment?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<InventoryAdjustment> AddAsync(InventoryAdjustment adjustment, CancellationToken cancellationToken = default);
    Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default);
}
