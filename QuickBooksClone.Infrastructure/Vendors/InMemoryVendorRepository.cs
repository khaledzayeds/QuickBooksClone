using System.Collections.Concurrent;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Infrastructure.Vendors;

public sealed class InMemoryVendorRepository : IVendorRepository
{
    private readonly ConcurrentDictionary<Guid, Vendor> _vendors = new();

    public InMemoryVendorRepository()
    {
        Seed(new Vendor("Cairo Office Supplies", "Cairo Office Supplies LLC", "orders@cairo-office.example", "+20 100 111 2222", "EGP", 0));
        Seed(new Vendor("Delta Hardware", "Delta Hardware Co.", "sales@delta-hardware.example", "+20 122 333 4444", "EGP", 3500));
        Seed(new Vendor("Nile Logistics", "Nile Logistics", "billing@nile-logistics.example", "+20 155 888 9999", "EGP", 0));
    }

    public Task<VendorListResult> SearchAsync(VendorSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _vendors.Values.AsEnumerable();

        if (!search.IncludeInactive)
        {
            query = query.Where(vendor => vendor.IsActive);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(vendor =>
                Contains(vendor.DisplayName, term) ||
                Contains(vendor.CompanyName, term) ||
                Contains(vendor.Email, term) ||
                Contains(vendor.Phone, term));
        }

        var ordered = query
            .OrderBy(vendor => vendor.DisplayName)
            .ToList();

        var items = ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Task.FromResult(new VendorListResult(items, ordered.Count, page, pageSize));
    }

    public Task<Vendor?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _vendors.TryGetValue(id, out var vendor);
        return Task.FromResult(vendor);
    }

    public Task<bool> DisplayNameExistsAsync(string displayName, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Exists(vendor => Same(vendor.DisplayName, displayName), excludingId));
    }

    public Task<bool> EmailExistsAsync(string email, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Exists(vendor => Same(vendor.Email, email), excludingId));
    }

    public Task<Vendor> AddAsync(Vendor vendor, CancellationToken cancellationToken = default)
    {
        _vendors[vendor.Id] = vendor;
        return Task.FromResult(vendor);
    }

    public Task<Vendor?> UpdateAsync(Guid id, string displayName, string? companyName, string? email, string? phone, string currency, CancellationToken cancellationToken = default)
    {
        if (!_vendors.TryGetValue(id, out var vendor))
        {
            return Task.FromResult<Vendor?>(null);
        }

        vendor.Update(displayName, companyName, email, phone, currency);
        return Task.FromResult<Vendor?>(vendor);
    }

    public Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default)
    {
        if (!_vendors.TryGetValue(id, out var vendor))
        {
            return Task.FromResult(false);
        }

        vendor.SetActive(isActive);
        return Task.FromResult(true);
    }

    public Task<bool> ApplyBillAsync(Guid id, decimal amount, CancellationToken cancellationToken = default)
    {
        if (!_vendors.TryGetValue(id, out var vendor))
        {
            return Task.FromResult(false);
        }

        vendor.ApplyBill(amount);
        return Task.FromResult(true);
    }

    public Task<bool> ReverseBillAsync(Guid id, decimal amount, CancellationToken cancellationToken = default)
    {
        if (!_vendors.TryGetValue(id, out var vendor))
        {
            return Task.FromResult(false);
        }

        vendor.ReverseBill(amount);
        return Task.FromResult(true);
    }

    public Task<bool> ApplyPaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default)
    {
        if (!_vendors.TryGetValue(id, out var vendor))
        {
            return Task.FromResult(false);
        }

        vendor.ApplyPayment(amount);
        return Task.FromResult(true);
    }

    private static bool Contains(string? value, string term)
    {
        return value?.Contains(term, StringComparison.OrdinalIgnoreCase) == true;
    }

    private bool Exists(Func<Vendor, bool> predicate, Guid? excludingId)
    {
        return _vendors.Values.Any(vendor => vendor.Id != excludingId && predicate(vendor));
    }

    private static bool Same(string? left, string right)
    {
        return string.Equals(left?.Trim(), right.Trim(), StringComparison.OrdinalIgnoreCase);
    }

    private void Seed(Vendor vendor)
    {
        _vendors[vendor.Id] = vendor;
    }
}
