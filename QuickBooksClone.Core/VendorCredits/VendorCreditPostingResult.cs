namespace QuickBooksClone.Core.VendorCredits;

public sealed record VendorCreditPostingResult(bool Succeeded, Guid? TransactionId, string? ErrorMessage)
{
    public static VendorCreditPostingResult Success(Guid? transactionId = null) => new(true, transactionId, null);
    public static VendorCreditPostingResult Failure(string errorMessage) => new(false, null, errorMessage);
}
