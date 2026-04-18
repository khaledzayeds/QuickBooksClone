namespace QuickBooksClone.Maui.Services.JournalEntries;

public sealed class JournalEntryLineFormModel
{
    public Guid AccountId { get; set; }
    public string? Description { get; set; }
    public decimal Debit { get; set; }
    public decimal Credit { get; set; }
}
