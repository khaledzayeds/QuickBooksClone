namespace QuickBooksClone.Core.PurchaseBills;

public interface IPurchaseBillPostingService
{
    Task<PurchaseBillPostingResult> PostAsync(Guid purchaseBillId, CancellationToken cancellationToken = default);
}
