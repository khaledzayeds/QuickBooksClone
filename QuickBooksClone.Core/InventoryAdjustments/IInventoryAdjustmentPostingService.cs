namespace QuickBooksClone.Core.InventoryAdjustments;

public interface IInventoryAdjustmentPostingService
{
    Task<InventoryAdjustmentPostingResult> PostAsync(Guid adjustmentId, CancellationToken cancellationToken = default);
}
