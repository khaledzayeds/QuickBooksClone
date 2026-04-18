namespace QuickBooksClone.Core.SalesReturns;

public interface ISalesReturnRepository
{
    Task<SalesReturnListResult> SearchAsync(SalesReturnSearch search, CancellationToken cancellationToken = default);
    Task<SalesReturn?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<SalesReturn> AddAsync(SalesReturn salesReturn, CancellationToken cancellationToken = default);
    Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default);
}
