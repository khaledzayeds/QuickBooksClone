namespace QuickBooksClone.Maui.Services.JournalEntries;

public sealed record JournalEntryLineDto(
    Guid Id,
    Guid AccountId,
    string? AccountCode,
    string? AccountName,
    string Description,
    decimal Debit,
    decimal Credit);
