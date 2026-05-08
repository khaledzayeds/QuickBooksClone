namespace QuickBooksClone.Api.Contracts;

public sealed record RunJournalLinksDto(
    Guid RunId,
    Guid? JournalEntryId,
    Guid? ReversalJournalEntryId,
    bool HasOriginalJournal,
    bool HasReversalJournal);
