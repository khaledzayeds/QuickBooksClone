namespace QuickBooksClone.Maui.Services.JournalEntries;

public sealed record JournalEntryDto(
    Guid Id,
    string EntryNumber,
    DateOnly EntryDate,
    string Memo,
    JournalEntryStatus Status,
    decimal TotalDebit,
    decimal TotalCredit,
    Guid? PostedTransactionId,
    Guid? ReversalTransactionId,
    DateTimeOffset? PostedAt,
    DateTimeOffset? VoidedAt,
    IReadOnlyList<JournalEntryLineDto> Lines);
