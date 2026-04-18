using System.Collections.Concurrent;
using QuickBooksClone.Core.Payments;

namespace QuickBooksClone.Infrastructure.Payments;

public sealed class InMemoryPaymentRepository : IPaymentRepository
{
    private readonly ConcurrentDictionary<Guid, Payment> _payments = new();

    public Task<PaymentListResult> SearchAsync(PaymentSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _payments.Values.AsEnumerable();

        if (!search.IncludeVoid)
        {
            query = query.Where(payment => payment.Status != PaymentStatus.Void);
        }

        if (search.CustomerId is not null)
        {
            query = query.Where(payment => payment.CustomerId == search.CustomerId);
        }

        if (search.InvoiceId is not null)
        {
            query = query.Where(payment => payment.InvoiceId == search.InvoiceId);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(payment =>
                payment.PaymentNumber.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                payment.PaymentMethod.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = query
            .OrderByDescending(payment => payment.PaymentDate)
            .ThenByDescending(payment => payment.CreatedAt)
            .ToList();

        var items = ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Task.FromResult(new PaymentListResult(items, ordered.Count, page, pageSize));
    }

    public Task<Payment?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _payments.TryGetValue(id, out var payment);
        return Task.FromResult(payment);
    }

    public Task<Payment> AddAsync(Payment payment, CancellationToken cancellationToken = default)
    {
        _payments[payment.Id] = payment;
        return Task.FromResult(payment);
    }

    public Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default)
    {
        if (!_payments.TryGetValue(id, out var payment))
        {
            return Task.FromResult(false);
        }

        payment.MarkPosted(transactionId);
        return Task.FromResult(true);
    }

    public Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default)
    {
        if (!_payments.TryGetValue(id, out var payment))
        {
            return Task.FromResult(false);
        }

        payment.Void(reversalTransactionId);
        return Task.FromResult(true);
    }
}
