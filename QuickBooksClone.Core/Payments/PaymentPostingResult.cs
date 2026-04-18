namespace QuickBooksClone.Core.Payments;

public sealed record PaymentPostingResult(
    bool Succeeded,
    Guid? TransactionId,
    string? ErrorMessage)
{
    public static PaymentPostingResult Success(Guid? transactionId = null)
    {
        return new PaymentPostingResult(true, transactionId, null);
    }

    public static PaymentPostingResult Failure(string errorMessage)
    {
        return new PaymentPostingResult(false, null, errorMessage);
    }
}
