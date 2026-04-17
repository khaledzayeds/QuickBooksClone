using System.Collections.Concurrent;
using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Infrastructure.Accounting;

public sealed class InMemoryAccountingTransactionRepository : IAccountingTransactionRepository
{
    private readonly ConcurrentDictionary<Guid, AccountingTransaction> _transactions = new();

    public Task<AccountingTransactionListResult> SearchAsync(AccountingTransactionSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 200);
        var query = _transactions.Values.AsEnumerable();

        if (!search.IncludeVoided)
        {
            query = query.Where(transaction => transaction.Status != AccountingTransactionStatus.Voided);
        }

        if (!string.IsNullOrWhiteSpace(search.SourceEntityType))
        {
            query = query.Where(transaction => transaction.SourceEntityType == search.SourceEntityType);
        }

        if (search.SourceEntityId is not null)
        {
            query = query.Where(transaction => transaction.SourceEntityId == search.SourceEntityId);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(transaction =>
                transaction.ReferenceNumber.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                transaction.TransactionType.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = query
            .OrderByDescending(transaction => transaction.TransactionDate)
            .ThenByDescending(transaction => transaction.CreatedAt)
            .ToList();

        var items = ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Task.FromResult(new AccountingTransactionListResult(items, ordered.Count, page, pageSize));
    }

    public Task<AccountingTransaction?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _transactions.TryGetValue(id, out var transaction);
        return Task.FromResult(transaction);
    }

    public Task<AccountingTransaction?> GetBySourceAsync(string sourceEntityType, Guid sourceEntityId, CancellationToken cancellationToken = default)
    {
        var transaction = _transactions.Values.FirstOrDefault(current =>
            current.SourceEntityType == sourceEntityType &&
            current.SourceEntityId == sourceEntityId &&
            current.Status != AccountingTransactionStatus.Voided);

        return Task.FromResult(transaction);
    }

    public Task<AccountingTransaction> AddAsync(AccountingTransaction transaction, CancellationToken cancellationToken = default)
    {
        transaction.ValidateBalanced();
        _transactions[transaction.Id] = transaction;
        return Task.FromResult(transaction);
    }
}
