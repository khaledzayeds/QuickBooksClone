namespace QuickBooksClone.Core.PurchaseBills;

public sealed record PurchaseBillPostingResult(
    bool Succeeded,
    Guid? TransactionId,
    string? ErrorMessage)
{
    public static PurchaseBillPostingResult Success(Guid? transactionId = null)
    {
        return new PurchaseBillPostingResult(true, transactionId, null);
    }

    public static PurchaseBillPostingResult Failure(string errorMessage)
    {
        return new PurchaseBillPostingResult(false, null, errorMessage);
    }
}
