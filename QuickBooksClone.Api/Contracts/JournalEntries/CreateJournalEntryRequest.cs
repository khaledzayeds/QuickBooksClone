using QuickBooksClone.Core.JournalEntries;

namespace QuickBooksClone.Api.Contracts.JournalEntries;

public sealed record CreateJournalEntryRequest(
    DateOnly EntryDate,
    string? Memo,
    JournalEntrySaveMode SaveMode,
    IReadOnlyList<CreateJournalEntryLineRequest> Lines);
