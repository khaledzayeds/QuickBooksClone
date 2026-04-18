namespace QuickBooksClone.Core.VendorCredits;

public interface IVendorCreditActivityRepository
{
    Task<VendorCreditActivityListResult> SearchAsync(VendorCreditActivitySearch search, CancellationToken cancellationToken = default);
    Task<VendorCreditActivity?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<VendorCreditActivity> AddAsync(VendorCreditActivity activity, CancellationToken cancellationToken = default);
    Task<bool> MarkPostedAsync(Guid id, Guid? transactionId = null, CancellationToken cancellationToken = default);
}
