namespace QuickBooksClone.Core.JournalEntries;

public interface IJournalEntryRepository
{
    Task<JournalEntryListResult> SearchAsync(JournalEntrySearch search, CancellationToken cancellationToken = default);
    Task<JournalEntry?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<JournalEntry> AddAsync(JournalEntry journalEntry, CancellationToken cancellationToken = default);
    Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default);
    Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId, CancellationToken cancellationToken = default);
}
