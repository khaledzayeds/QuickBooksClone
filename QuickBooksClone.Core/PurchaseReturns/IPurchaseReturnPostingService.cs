namespace QuickBooksClone.Core.PurchaseReturns;

public interface IPurchaseReturnPostingService
{
    Task<PurchaseReturnPostingResult> PostAsync(Guid purchaseReturnId, CancellationToken cancellationToken = default);
}
