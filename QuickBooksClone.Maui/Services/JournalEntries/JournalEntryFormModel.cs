namespace QuickBooksClone.Maui.Services.JournalEntries;

public sealed class JournalEntryFormModel
{
    public DateOnly EntryDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public string? Memo { get; set; }
    public JournalEntrySaveMode SaveMode { get; set; } = JournalEntrySaveMode.SaveAndPost;
    public List<JournalEntryLineFormModel> Lines { get; set; } =
    [
        new(),
        new()
    ];
}
