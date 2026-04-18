namespace QuickBooksClone.Core.VendorPayments;

public interface IVendorPaymentRepository
{
    Task<VendorPaymentListResult> SearchAsync(VendorPaymentSearch search, CancellationToken cancellationToken = default);
    Task<VendorPayment?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<VendorPayment> AddAsync(VendorPayment payment, CancellationToken cancellationToken = default);
    Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default);
    Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default);
}
