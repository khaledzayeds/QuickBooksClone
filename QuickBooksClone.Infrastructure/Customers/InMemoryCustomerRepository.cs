using System.Collections.Concurrent;
using QuickBooksClone.Core.Customers;

namespace QuickBooksClone.Infrastructure.Customers;

public sealed class InMemoryCustomerRepository : ICustomerRepository
{
    private readonly ConcurrentDictionary<Guid, Customer> _customers = new();

    public InMemoryCustomerRepository()
    {
        Seed(new Customer("Ahmed Mohamed", "Solution SA", "ahmed@solution.sa", "+966 123 50 4567", "EGP", 12450));
        Seed(new Customer("Sara Ali", "Horizon International", "s.ali@horizon.com", "+966 456 888 2121", "EGP", 0));
        Seed(new Customer("Khaled Mansour", "Mansour Stores", "k.mansour@shop.sa", "+966 565 990 1010", "EGP", 2100));
    }

    public Task<CustomerListResult> SearchAsync(CustomerSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _customers.Values.AsEnumerable();

        if (!search.IncludeInactive)
        {
            query = query.Where(customer => customer.IsActive);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(customer =>
                Contains(customer.DisplayName, term) ||
                Contains(customer.CompanyName, term) ||
                Contains(customer.Email, term) ||
                Contains(customer.Phone, term));
        }

        var ordered = query
            .OrderBy(customer => customer.DisplayName)
            .ToList();

        var items = ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Task.FromResult(new CustomerListResult(items, ordered.Count, page, pageSize));
    }

    public Task<Customer?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _customers.TryGetValue(id, out var customer);
        return Task.FromResult(customer);
    }

    public Task<bool> DisplayNameExistsAsync(string displayName, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Exists(customer => Same(customer.DisplayName, displayName), excludingId));
    }

    public Task<bool> EmailExistsAsync(string email, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Exists(customer => Same(customer.Email, email), excludingId));
    }

    public Task<Customer> AddAsync(Customer customer, CancellationToken cancellationToken = default)
    {
        _customers[customer.Id] = customer;
        return Task.FromResult(customer);
    }

    public Task<Customer?> UpdateAsync(Guid id, string displayName, string? companyName, string? email, string? phone, string currency, CancellationToken cancellationToken = default)
    {
        if (!_customers.TryGetValue(id, out var customer))
        {
            return Task.FromResult<Customer?>(null);
        }

        customer.Update(displayName, companyName, email, phone, currency);
        return Task.FromResult<Customer?>(customer);
    }

    public Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default)
    {
        if (!_customers.TryGetValue(id, out var customer))
        {
            return Task.FromResult(false);
        }

        customer.SetActive(isActive);
        return Task.FromResult(true);
    }

    public Task<bool> AddCreditAsync(Guid id, decimal amount, CancellationToken cancellationToken = default)
    {
        if (!_customers.TryGetValue(id, out var customer))
        {
            return Task.FromResult(false);
        }

        customer.AddCredit(amount);
        return Task.FromResult(true);
    }

    public Task<bool> UseCreditAsync(Guid id, decimal amount, CancellationToken cancellationToken = default)
    {
        if (!_customers.TryGetValue(id, out var customer))
        {
            return Task.FromResult(false);
        }

        customer.UseCredit(amount);
        return Task.FromResult(true);
    }

    private static bool Contains(string? value, string term)
    {
        return value?.Contains(term, StringComparison.OrdinalIgnoreCase) == true;
    }

    private bool Exists(Func<Customer, bool> predicate, Guid? excludingId)
    {
        return _customers.Values.Any(customer => customer.Id != excludingId && predicate(customer));
    }

    private static bool Same(string? left, string right)
    {
        return string.Equals(left?.Trim(), right.Trim(), StringComparison.OrdinalIgnoreCase);
    }

    private void Seed(Customer customer)
    {
        _customers[customer.Id] = customer;
    }
}
