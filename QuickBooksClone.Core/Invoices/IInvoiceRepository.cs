namespace QuickBooksClone.Core.Invoices;

public interface IInvoiceRepository
{
    Task<InvoiceListResult> SearchAsync(InvoiceSearch search, CancellationToken cancellationToken = default);
    Task<Invoice?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Invoice> AddAsync(Invoice invoice, CancellationToken cancellationToken = default);
    Task<bool> MarkSentAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default);
    Task<bool> ApplyPaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> LinkReceiptPaymentAsync(Guid id, Guid paymentId, CancellationToken cancellationToken = default);
    Task<bool> ReversePaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> ApplyCreditAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> ApplyReturnAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> ReverseReturnAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default);
}
