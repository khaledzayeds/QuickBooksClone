namespace QuickBooksClone.Core.PurchaseBills;

public interface IPurchaseBillRepository
{
    Task<PurchaseBillListResult> SearchAsync(PurchaseBillSearch search, CancellationToken cancellationToken = default);
    Task<PurchaseBill?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<PurchaseBill> AddAsync(PurchaseBill bill, CancellationToken cancellationToken = default);
    Task<Dictionary<Guid, decimal>> GetBilledQuantitiesByInventoryReceiptLineIdsAsync(IEnumerable<Guid> inventoryReceiptLineIds, CancellationToken cancellationToken = default);
    Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default);
    Task<bool> ApplyPaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> ReversePaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> ApplyCreditAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> ApplyReturnAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> ReverseReturnAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default);
}
