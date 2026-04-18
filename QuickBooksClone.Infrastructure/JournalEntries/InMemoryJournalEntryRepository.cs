using System.Collections.Concurrent;
using QuickBooksClone.Core.JournalEntries;

namespace QuickBooksClone.Infrastructure.JournalEntries;

public sealed class InMemoryJournalEntryRepository : IJournalEntryRepository
{
    private readonly ConcurrentDictionary<Guid, JournalEntry> _journalEntries = new();

    public Task<JournalEntryListResult> SearchAsync(JournalEntrySearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _journalEntries.Values.AsEnumerable();

        if (!search.IncludeVoid)
        {
            query = query.Where(entry => entry.Status != JournalEntryStatus.Void);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(entry =>
                entry.EntryNumber.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                entry.Memo.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = query
            .OrderByDescending(entry => entry.EntryDate)
            .ThenByDescending(entry => entry.CreatedAt)
            .ToList();

        var items = ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Task.FromResult(new JournalEntryListResult(items, ordered.Count, page, pageSize));
    }

    public Task<JournalEntry?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _journalEntries.TryGetValue(id, out var journalEntry);
        return Task.FromResult(journalEntry);
    }

    public Task<JournalEntry> AddAsync(JournalEntry journalEntry, CancellationToken cancellationToken = default)
    {
        _journalEntries[journalEntry.Id] = journalEntry;
        return Task.FromResult(journalEntry);
    }

    public Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default)
    {
        if (!_journalEntries.TryGetValue(id, out var journalEntry))
        {
            return Task.FromResult(false);
        }

        journalEntry.MarkPosted(transactionId);
        return Task.FromResult(true);
    }

    public Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId, CancellationToken cancellationToken = default)
    {
        if (!_journalEntries.TryGetValue(id, out var journalEntry))
        {
            return Task.FromResult(false);
        }

        journalEntry.Void(reversalTransactionId);
        return Task.FromResult(true);
    }
}
