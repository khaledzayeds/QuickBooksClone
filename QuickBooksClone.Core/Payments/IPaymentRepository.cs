namespace QuickBooksClone.Core.Payments;

public interface IPaymentRepository
{
    Task<PaymentListResult> SearchAsync(PaymentSearch search, CancellationToken cancellationToken = default);
    Task<Payment?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Payment> AddAsync(Payment payment, CancellationToken cancellationToken = default);
    Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default);
    Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default);
}
