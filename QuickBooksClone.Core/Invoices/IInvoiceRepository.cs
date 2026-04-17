namespace QuickBooksClone.Core.Invoices;

public interface IInvoiceRepository
{
    Task<InvoiceListResult> SearchAsync(InvoiceSearch search, CancellationToken cancellationToken = default);
    Task<Invoice?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Invoice> AddAsync(Invoice invoice, CancellationToken cancellationToken = default);
    Task<bool> MarkSentAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default);
    Task<bool> VoidAsync(Guid id, CancellationToken cancellationToken = default);
}
