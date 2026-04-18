namespace QuickBooksClone.Core.OpeningBalances;

public sealed record OpeningBalancePostingResult(
    bool Succeeded,
    Guid? TransactionId,
    string? ErrorMessage)
{
    public static OpeningBalancePostingResult Success(Guid? transactionId = null)
    {
        return new OpeningBalancePostingResult(true, transactionId, null);
    }

    public static OpeningBalancePostingResult Failure(string errorMessage)
    {
        return new OpeningBalancePostingResult(false, null, errorMessage);
    }
}
