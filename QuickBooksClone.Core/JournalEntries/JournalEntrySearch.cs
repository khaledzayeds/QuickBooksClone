namespace QuickBooksClone.Core.JournalEntries;

public sealed record JournalEntrySearch(
    string? Search,
    bool IncludeVoid = false,
    int Page = 1,
    int PageSize = 25);
