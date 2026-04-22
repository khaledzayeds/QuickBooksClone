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

        if (search.InventoryReceiptId is not null)
        {
            query = query.Where(bill => bill.InventoryReceiptId == search.InventoryReceiptId);
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

    public Task<Dictionary<Guid, decimal>> GetBilledQuantitiesByInventoryReceiptLineIdsAsync(IEnumerable<Guid> inventoryReceiptLineIds, CancellationToken cancellationToken = default)
    {
        var lineIds = inventoryReceiptLineIds.Where(id => id != Guid.Empty).Distinct().ToHashSet();
        if (lineIds.Count == 0)
        {
            return Task.FromResult<Dictionary<Guid, decimal>>([]);
        }

        var quantities = _bills.Values
            .Where(bill => bill.Status != PurchaseBillStatus.Void)
            .SelectMany(bill => bill.Lines)
            .Where(line => line.InventoryReceiptLineId.HasValue && lineIds.Contains(line.InventoryReceiptLineId.Value))
            .GroupBy(line => line.InventoryReceiptLineId!.Value)
            .ToDictionary(group => group.Key, group => group.Sum(line => line.Quantity));

        return Task.FromResult(quantities);
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

    public Task<bool> ApplyPaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default)
    {
        if (!_bills.TryGetValue(id, out var bill))
        {
            return Task.FromResult(false);
        }

        bill.ApplyPayment(amount);
        return Task.FromResult(true);
    }

    public Task<bool> ReversePaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default)
    {
        if (!_bills.TryGetValue(id, out var bill))
        {
            return Task.FromResult(false);
        }

        bill.ReversePayment(amount);
        return Task.FromResult(true);
    }

    public Task<bool> ApplyCreditAsync(Guid id, decimal amount, CancellationToken cancellationToken = default)
    {
        if (!_bills.TryGetValue(id, out var bill))
        {
            return Task.FromResult(false);
        }

        bill.ApplyCredit(amount);
        return Task.FromResult(true);
    }

    public Task<bool> ApplyReturnAsync(Guid id, decimal amount, CancellationToken cancellationToken = default)
    {
        if (!_bills.TryGetValue(id, out var bill))
        {
            return Task.FromResult(false);
        }

        bill.ApplyReturn(amount);
        return Task.FromResult(true);
    }

    public Task<bool> ReverseReturnAsync(Guid id, decimal amount, CancellationToken cancellationToken = default)
    {
        if (!_bills.TryGetValue(id, out var bill))
        {
            return Task.FromResult(false);
        }

        bill.ReverseReturn(amount);
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
