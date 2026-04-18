namespace QuickBooksClone.Core.JournalEntries;

public sealed record JournalEntryPostingResult(bool Succeeded, string? ErrorMessage = null, Guid? TransactionId = null)
{
    public static JournalEntryPostingResult Success(Guid? transactionId = null) => new(true, null, transactionId);
    public static JournalEntryPostingResult Failure(string errorMessage) => new(false, errorMessage);
}
