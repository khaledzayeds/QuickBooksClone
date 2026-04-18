namespace QuickBooksClone.Core.VendorPayments;

public sealed record VendorPaymentPostingResult(
    bool Succeeded,
    Guid? TransactionId,
    string? ErrorMessage)
{
    public static VendorPaymentPostingResult Success(Guid? transactionId = null)
    {
        return new VendorPaymentPostingResult(true, transactionId, null);
    }

    public static VendorPaymentPostingResult Failure(string errorMessage)
    {
        return new VendorPaymentPostingResult(false, null, errorMessage);
    }
}
