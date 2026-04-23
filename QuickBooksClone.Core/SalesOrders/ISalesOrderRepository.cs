namespace QuickBooksClone.Core.SalesOrders;

public interface ISalesOrderRepository
{
    Task<SalesOrderListResult> SearchAsync(SalesOrderSearch search, CancellationToken cancellationToken = default);
    Task<SalesOrder?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<SalesOrder> AddAsync(SalesOrder order, CancellationToken cancellationToken = default);
    Task<bool> MarkOpenAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> CloseAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> CancelAsync(Guid id, CancellationToken cancellationToken = default);
}
