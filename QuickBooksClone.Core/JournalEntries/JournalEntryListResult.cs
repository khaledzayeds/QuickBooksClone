namespace QuickBooksClone.Core.JournalEntries;

public sealed record JournalEntryListResult(
    IReadOnlyList<JournalEntry> Items,
    int TotalCount,
    int Page,
    int PageSize);
