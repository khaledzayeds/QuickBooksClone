using System.Collections.Concurrent;
using QuickBooksClone.Core.InventoryAdjustments;

namespace QuickBooksClone.Infrastructure.InventoryAdjustments;

public sealed class InMemoryInventoryAdjustmentRepository : IInventoryAdjustmentRepository
{
    private readonly ConcurrentDictionary<Guid, InventoryAdjustment> _adjustments = new();

    public Task<InventoryAdjustmentListResult> SearchAsync(InventoryAdjustmentSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _adjustments.Values.AsEnumerable();
        if (!search.IncludeVoid) query = query.Where(adjustment => adjustment.Status != InventoryAdjustmentStatus.Void);
        if (search.ItemId is not null) query = query.Where(adjustment => adjustment.ItemId == search.ItemId);
        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(adjustment => adjustment.AdjustmentNumber.Contains(term, StringComparison.OrdinalIgnoreCase) || adjustment.Reason.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = query.OrderByDescending(adjustment => adjustment.AdjustmentDate).ThenByDescending(adjustment => adjustment.CreatedAt).ToList();
        var items = ordered.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        return Task.FromResult(new InventoryAdjustmentListResult(items, ordered.Count, page, pageSize));
    }

    public Task<InventoryAdjustment?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _adjustments.TryGetValue(id, out var adjustment);
        return Task.FromResult(adjustment);
    }

    public Task<InventoryAdjustment> AddAsync(InventoryAdjustment adjustment, CancellationToken cancellationToken = default)
    {
        _adjustments[adjustment.Id] = adjustment;
        return Task.FromResult(adjustment);
    }

    public Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default)
    {
        if (!_adjustments.TryGetValue(id, out var adjustment))
        {
            return Task.FromResult(false);
        }

        adjustment.MarkPosted(transactionId);
        return Task.FromResult(true);
    }
}
