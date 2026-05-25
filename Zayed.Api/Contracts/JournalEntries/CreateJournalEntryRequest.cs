using Zayed.Core.JournalEntries;

namespace Zayed.Api.Contracts.JournalEntries;

public sealed record CreateJournalEntryRequest(
    DateOnly EntryDate,
    string? Memo,
    JournalEntrySaveMode SaveMode,
    IReadOnlyList<CreateJournalEntryLineRequest> Lines);
