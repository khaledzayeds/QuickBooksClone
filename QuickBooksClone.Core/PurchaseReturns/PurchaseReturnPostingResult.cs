namespace QuickBooksClone.Core.PurchaseReturns;

public sealed record PurchaseReturnPostingResult(bool Succeeded, Guid? TransactionId, string? ErrorMessage)
{
    public static PurchaseReturnPostingResult Success(Guid? transactionId = null) => new(true, transactionId, null);
    public static PurchaseReturnPostingResult Failure(string errorMessage) => new(false, null, errorMessage);
}
