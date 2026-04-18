namespace QuickBooksClone.Core.Invoices;

public sealed record InvoicePostingResult(
    bool Succeeded,
    Guid? TransactionId,
    string? ErrorMessage)
{
    public static InvoicePostingResult Success(Guid? transactionId = null)
    {
        return new InvoicePostingResult(true, transactionId, null);
    }

    public static InvoicePostingResult Failure(string errorMessage)
    {
        return new InvoicePostingResult(false, null, errorMessage);
    }
}
