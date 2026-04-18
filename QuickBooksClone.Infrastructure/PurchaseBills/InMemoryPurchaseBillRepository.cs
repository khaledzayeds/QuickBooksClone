using System.Collections.Concurrent;
using QuickBooksClone.Core.PurchaseBills;

namespace QuickBooksClone.Infrastructure.PurchaseBills;

public sealed class InMemoryPurchaseBillRepository : IPurchaseBillRepository
{
    private readonly ConcurrentDictionary<Guid, PurchaseBill> _bills = new();

    public Task<PurchaseBillListResult> SearchAsync(PurchaseBillSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _bills.Values.AsEnumerable();

        if (!search.IncludeVoid)
        {
            query = query.Where(bill => bill.Status != PurchaseBillStatus.Void);
        }

        if (search.VendorId is not null)
        {
            query = query.Where(bill => bill.VendorId == search.VendorId);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(bill => bill.BillNumber.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = query
            .OrderByDescending(bill => bill.BillDate)
            .ThenByDescending(bill => bill.CreatedAt)
            .ToList();

        var items = ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Task.FromResult(new PurchaseBillListResult(items, ordered.Count, page, pageSize));
    }

    public Task<PurchaseBill?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _bills.TryGetValue(id, out var bill);
        return Task.FromResult(bill);
    }

    public Task<PurchaseBill> AddAsync(PurchaseBill bill, CancellationToken cancellationToken = default)
    {
        _bills[bill.Id] = bill;
        return Task.FromResult(bill);
    }

    public Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default)
    {
        if (!_bills.TryGetValue(id, out var bill))
        {
            return Task.FromResult(false);
        }

        bill.MarkPosted(transactionId);
        return Task.FromResult(true);
    }

    public Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default)
    {
        if (!_bills.TryGetValue(id, out var bill))
        {
            return Task.FromResult(false);
        }

        bill.Void(reversalTransactionId);
        return Task.FromResult(true);
    }
}
