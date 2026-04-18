using System.Collections.Concurrent;
using QuickBooksClone.Core.PurchaseReturns;

namespace QuickBooksClone.Infrastructure.PurchaseReturns;

public sealed class InMemoryPurchaseReturnRepository : IPurchaseReturnRepository
{
    private readonly ConcurrentDictionary<Guid, PurchaseReturn> _returns = new();

    public Task<PurchaseReturnListResult> SearchAsync(PurchaseReturnSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _returns.Values.AsEnumerable();
        if (!search.IncludeVoid) query = query.Where(item => item.Status != PurchaseReturnStatus.Void);
        if (search.PurchaseBillId is not null) query = query.Where(item => item.PurchaseBillId == search.PurchaseBillId);
        if (search.VendorId is not null) query = query.Where(item => item.VendorId == search.VendorId);
        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(item => item.ReturnNumber.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = query.OrderByDescending(item => item.ReturnDate).ThenByDescending(item => item.CreatedAt).ToList();
        var items = ordered.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        return Task.FromResult(new PurchaseReturnListResult(items, ordered.Count, page, pageSize));
    }

    public Task<PurchaseReturn?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _returns.TryGetValue(id, out var purchaseReturn);
        return Task.FromResult(purchaseReturn);
    }

    public Task<PurchaseReturn> AddAsync(PurchaseReturn purchaseReturn, CancellationToken cancellationToken = default)
    {
        _returns[purchaseReturn.Id] = purchaseReturn;
        return Task.FromResult(purchaseReturn);
    }

    public Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default)
    {
        if (!_returns.TryGetValue(id, out var purchaseReturn)) return Task.FromResult(false);
        purchaseReturn.MarkPosted(transactionId);
        return Task.FromResult(true);
    }
}
