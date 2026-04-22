namespace QuickBooksClone.Core.PurchaseReturns;

public interface IPurchaseReturnRepository
{
    Task<PurchaseReturnListResult> SearchAsync(PurchaseReturnSearch search, CancellationToken cancellationToken = default);
    Task<PurchaseReturn?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<PurchaseReturn> AddAsync(PurchaseReturn purchaseReturn, CancellationToken cancellationToken = default);
    Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default);
    Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default);
}
