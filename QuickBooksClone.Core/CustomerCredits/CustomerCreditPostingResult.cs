namespace QuickBooksClone.Core.CustomerCredits;

public sealed record CustomerCreditPostingResult(bool Succeeded, Guid? TransactionId, string? ErrorMessage)
{
    public static CustomerCreditPostingResult Success(Guid? transactionId = null)
    {
        return new CustomerCreditPostingResult(true, transactionId, null);
    }

    public static CustomerCreditPostingResult Failure(string errorMessage)
    {
        return new CustomerCreditPostingResult(false, null, errorMessage);
    }
}
