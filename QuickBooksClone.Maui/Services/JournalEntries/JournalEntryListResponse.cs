namespace QuickBooksClone.Maui.Services.JournalEntries;

public sealed record JournalEntryListResponse(
    IReadOnlyList<JournalEntryDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
