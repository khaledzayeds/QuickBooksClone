using System.Collections.Concurrent;
using QuickBooksClone.Core.VendorPayments;

namespace QuickBooksClone.Infrastructure.VendorPayments;

public sealed class InMemoryVendorPaymentRepository : IVendorPaymentRepository
{
    private readonly ConcurrentDictionary<Guid, VendorPayment> _payments = new();

    public Task<VendorPaymentListResult> SearchAsync(VendorPaymentSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _payments.Values.AsEnumerable();

        if (!search.IncludeVoid)
        {
            query = query.Where(payment => payment.Status != VendorPaymentStatus.Void);
        }

        if (search.VendorId is not null)
        {
            query = query.Where(payment => payment.VendorId == search.VendorId);
        }

        if (search.PurchaseBillId is not null)
        {
            query = query.Where(payment => payment.PurchaseBillId == search.PurchaseBillId);
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

        return Task.FromResult(new VendorPaymentListResult(items, ordered.Count, page, pageSize));
    }

    public Task<VendorPayment?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _payments.TryGetValue(id, out var payment);
        return Task.FromResult(payment);
    }

    public Task<VendorPayment> AddAsync(VendorPayment payment, CancellationToken cancellationToken = default)
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
}
