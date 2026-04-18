namespace QuickBooksClone.Core.JournalEntries;

public interface IJournalEntryPostingService
{
    Task<JournalEntryPostingResult> PostAsync(Guid journalEntryId, CancellationToken cancellationToken = default);
    Task<JournalEntryPostingResult> VoidAsync(Guid journalEntryId, CancellationToken cancellationToken = default);
}
