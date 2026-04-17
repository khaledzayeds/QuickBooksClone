namespace QuickBooksClone.Core.Invoices;

public interface ISalesInvoicePostingService
{
    Task<InvoicePostingResult> PostAsync(Guid invoiceId, CancellationToken cancellationToken = default);
}
