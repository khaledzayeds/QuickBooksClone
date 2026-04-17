namespace QuickBooksClone.Core.Customers;

public interface ICustomerRepository
{
    Task<CustomerListResult> SearchAsync(CustomerSearch search, CancellationToken cancellationToken = default);
    Task<Customer?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> DisplayNameExistsAsync(string displayName, Guid? excludingId = null, CancellationToken cancellationToken = default);
    Task<bool> EmailExistsAsync(string email, Guid? excludingId = null, CancellationToken cancellationToken = default);
    Task<Customer> AddAsync(Customer customer, CancellationToken cancellationToken = default);
    Task<Customer?> UpdateAsync(Guid id, string displayName, string? companyName, string? email, string? phone, string currency, CancellationToken cancellationToken = default);
    Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default);
}
