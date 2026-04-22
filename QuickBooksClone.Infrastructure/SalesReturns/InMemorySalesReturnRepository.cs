using System.Collections.Concurrent;
using QuickBooksClone.Core.SalesReturns;

namespace QuickBooksClone.Infrastructure.SalesReturns;

public sealed class InMemorySalesReturnRepository : ISalesReturnRepository
{
    private readonly ConcurrentDictionary<Guid, SalesReturn> _salesReturns = new();

    public Task<SalesReturnListResult> SearchAsync(SalesReturnSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _salesReturns.Values.AsEnumerable();

        if (!search.IncludeVoid)
        {
            query = query.Where(salesReturn => salesReturn.Status != SalesReturnStatus.Void);
        }

        if (search.InvoiceId is not null)
        {
            query = query.Where(salesReturn => salesReturn.InvoiceId == search.InvoiceId);
        }

        if (search.CustomerId is not null)
        {
            query = query.Where(salesReturn => salesReturn.CustomerId == search.CustomerId);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(salesReturn => salesReturn.ReturnNumber.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = query
            .OrderByDescending(salesReturn => salesReturn.ReturnDate)
            .ThenByDescending(salesReturn => salesReturn.CreatedAt)
            .ToList();

        var items = ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Task.FromResult(new SalesReturnListResult(items, ordered.Count, page, pageSize));
    }

    public Task<SalesReturn?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _salesReturns.TryGetValue(id, out var salesReturn);
        return Task.FromResult(salesReturn);
    }

    public Task<SalesReturn> AddAsync(SalesReturn salesReturn, CancellationToken cancellationToken = default)
    {
        _salesReturns[salesReturn.Id] = salesReturn;
        return Task.FromResult(salesReturn);
    }

    public Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default)
    {
        if (!_salesReturns.TryGetValue(id, out var salesReturn))
        {
            return Task.FromResult(false);
        }

        salesReturn.MarkPosted(transactionId);
        return Task.FromResult(true);
    }

    public Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default)
    {
        if (!_salesReturns.TryGetValue(id, out var salesReturn))
        {
            return Task.FromResult(false);
        }

        salesReturn.Void(reversalTransactionId);
        return Task.FromResult(true);
    }
}
