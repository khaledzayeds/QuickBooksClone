namespace QuickBooksClone.Core.SalesReturns;

public interface ISalesReturnPostingService
{
    Task<SalesReturnPostingResult> PostAsync(Guid salesReturnId, CancellationToken cancellationToken = default);
}
