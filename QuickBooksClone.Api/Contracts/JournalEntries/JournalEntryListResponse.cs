namespace QuickBooksClone.Api.Contracts.JournalEntries;

public sealed record JournalEntryListResponse(
    IReadOnlyList<JournalEntryDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
