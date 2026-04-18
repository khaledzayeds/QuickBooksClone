namespace QuickBooksClone.Core.Vendors;

public interface IVendorRepository
{
    Task<VendorListResult> SearchAsync(VendorSearch search, CancellationToken cancellationToken = default);
    Task<Vendor?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> DisplayNameExistsAsync(string displayName, Guid? excludingId = null, CancellationToken cancellationToken = default);
    Task<bool> EmailExistsAsync(string email, Guid? excludingId = null, CancellationToken cancellationToken = default);
    Task<Vendor> AddAsync(Vendor vendor, CancellationToken cancellationToken = default);
    Task<Vendor?> UpdateAsync(Guid id, string displayName, string? companyName, string? email, string? phone, string currency, CancellationToken cancellationToken = default);
    Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default);
    Task<bool> ApplyBillAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> ReverseBillAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> ApplyPaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
    Task<bool> ReversePaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default);
}
