using System.Collections.Concurrent;
using QuickBooksClone.Core.Invoices;

namespace QuickBooksClone.Infrastructure.Invoices;

public sealed class InMemoryInvoiceRepository : IInvoiceRepository
{
    private readonly ConcurrentDictionary<Guid, Invoice> _invoices = new();

    public Task<InvoiceListResult> SearchAsync(InvoiceSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _invoices.Values.AsEnumerable();

        if (!search.IncludeVoid)
        {
            query = query.Where(invoice => invoice.Status != InvoiceStatus.Void);
        }

        if (search.CustomerId is not null)
        {
            query = query.Where(invoice => invoice.CustomerId == search.CustomerId);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(invoice => invoice.InvoiceNumber.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = query
            .OrderByDescending(invoice => invoice.InvoiceDate)
            .ThenByDescending(invoice => invoice.CreatedAt)
            .ToList();

        var items = ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Task.FromResult(new InvoiceListResult(items, ordered.Count, page, pageSize));
    }

    public Task<Invoice?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _invoices.TryGetValue(id, out var invoice);
        return Task.FromResult(invoice);
    }

    public Task<Invoice> AddAsync(Invoice invoice, CancellationToken cancellationToken = default)
    {
        _invoices[invoice.Id] = invoice;
        return Task.FromResult(invoice);
    }

    public Task<bool> MarkSentAsync(Guid id, CancellationToken cancellationToken = default)
    {
        if (!_invoices.TryGetValue(id, out var invoice))
        {
            return Task.FromResult(false);
        }

        invoice.MarkSent();
        return Task.FromResult(true);
    }

    public Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default)
    {
        if (!_invoices.TryGetValue(id, out var invoice))
        {
            return Task.FromResult(false);
        }

        invoice.MarkPosted(transactionId);
        return Task.FromResult(true);
    }

    public Task<bool> ApplyPaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default)
    {
        if (!_invoices.TryGetValue(id, out var invoice))
        {
            return Task.FromResult(false);
        }

        invoice.ApplyPayment(amount);
        return Task.FromResult(true);
    }

    public Task<bool> LinkReceiptPaymentAsync(Guid id, Guid paymentId, CancellationToken cancellationToken = default)
    {
        if (!_invoices.TryGetValue(id, out var invoice))
        {
            return Task.FromResult(false);
        }

        invoice.LinkReceiptPayment(paymentId);
        return Task.FromResult(true);
    }

    public Task<bool> ReversePaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default)
    {
        if (!_invoices.TryGetValue(id, out var invoice))
        {
            return Task.FromResult(false);
        }

        invoice.ReversePayment(amount);
        return Task.FromResult(true);
    }

    public Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default)
    {
        if (!_invoices.TryGetValue(id, out var invoice))
        {
            return Task.FromResult(false);
        }

        invoice.Void(reversalTransactionId);
        return Task.FromResult(true);
    }
}
