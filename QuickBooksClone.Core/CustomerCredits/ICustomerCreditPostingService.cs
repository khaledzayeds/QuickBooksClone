namespace QuickBooksClone.Core.CustomerCredits;

public interface ICustomerCreditPostingService
{
    Task<CustomerCreditPostingResult> PostAsync(Guid activityId, CancellationToken cancellationToken = default);
}
