namespace Zayed.Api.Contracts.JournalEntries;

public sealed record CreateJournalEntryLineRequest(
    Guid AccountId,
    string? Description,
    decimal Debit,
    decimal Credit);
