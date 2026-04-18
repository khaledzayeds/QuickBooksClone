namespace QuickBooksClone.Core.SalesReturns;

public sealed record SalesReturnPostingResult(bool Succeeded, Guid? TransactionId, string? ErrorMessage)
{
    public static SalesReturnPostingResult Success(Guid? transactionId = null)
    {
        return new SalesReturnPostingResult(true, transactionId, null);
    }

    public static SalesReturnPostingResult Failure(string errorMessage)
    {
        return new SalesReturnPostingResult(false, null, errorMessage);
    }
}
