namespace QuickBooksClone.Core.PurchaseOrders;

public interface IPurchaseOrderRepository
{
    Task<PurchaseOrderListResult> SearchAsync(PurchaseOrderSearch search, CancellationToken cancellationToken = default);
    Task<PurchaseOrder?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<PurchaseOrder> AddAsync(PurchaseOrder order, CancellationToken cancellationToken = default);
    Task<bool> MarkOpenAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> CloseAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> CancelAsync(Guid id, CancellationToken cancellationToken = default);
}
