namespace QuickBooksClone.Core.Payments;

public interface IPaymentPostingService
{
    Task<PaymentPostingResult> PostAsync(Guid paymentId, CancellationToken cancellationToken = default);
}
