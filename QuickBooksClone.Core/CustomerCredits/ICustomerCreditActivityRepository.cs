namespace QuickBooksClone.Core.CustomerCredits;

public interface ICustomerCreditActivityRepository
{
    Task<CustomerCreditActivityListResult> SearchAsync(CustomerCreditActivitySearch search, CancellationToken cancellationToken = default);
    Task<CustomerCreditActivity?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<CustomerCreditActivity> AddAsync(CustomerCreditActivity activity, CancellationToken cancellationToken = default);
    Task<bool> MarkPostedAsync(Guid id, Guid? transactionId = null, CancellationToken cancellationToken = default);
}
