namespace Zayed.Core.Invoices;

public interface ISalesInvoicePostingService
{
    Task<InvoicePostingResult> PostAsync(Guid invoiceId, CancellationToken cancellationToken = default);
    Task<InvoicePostingResult> VoidAsync(Guid invoiceId, CancellationToken cancellationToken = default);
}
