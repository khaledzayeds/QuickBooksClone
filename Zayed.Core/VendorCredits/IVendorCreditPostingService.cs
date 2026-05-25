namespace Zayed.Core.VendorCredits;

public interface IVendorCreditPostingService
{
    Task<VendorCreditPostingResult> PostAsync(Guid activityId, CancellationToken cancellationToken = default);
}
