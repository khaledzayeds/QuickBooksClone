namespace QuickBooksClone.Core.VendorPayments;

public interface IVendorPaymentPostingService
{
    Task<VendorPaymentPostingResult> PostAsync(Guid vendorPaymentId, CancellationToken cancellationToken = default);
    Task<VendorPaymentPostingResult> VoidAsync(Guid vendorPaymentId, CancellationToken cancellationToken = default);
}
