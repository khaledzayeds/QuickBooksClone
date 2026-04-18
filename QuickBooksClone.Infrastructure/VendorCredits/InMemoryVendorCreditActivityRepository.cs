using System.Collections.Concurrent;
using QuickBooksClone.Core.VendorCredits;

namespace QuickBooksClone.Infrastructure.VendorCredits;

public sealed class InMemoryVendorCreditActivityRepository : IVendorCreditActivityRepository
{
    private readonly ConcurrentDictionary<Guid, VendorCreditActivity> _activities = new();

    public Task<VendorCreditActivityListResult> SearchAsync(VendorCreditActivitySearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _activities.Values.AsEnumerable();
        if (!search.IncludeVoid) query = query.Where(activity => activity.Status != VendorCreditStatus.Void);
        if (search.VendorId is not null) query = query.Where(activity => activity.VendorId == search.VendorId);
        if (search.Action is not null) query = query.Where(activity => activity.Action == search.Action);
        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(activity => activity.ReferenceNumber.Contains(term, StringComparison.OrdinalIgnoreCase) || activity.PaymentMethod?.Contains(term, StringComparison.OrdinalIgnoreCase) == true);
        }

        var ordered = query.OrderByDescending(activity => activity.ActivityDate).ThenByDescending(activity => activity.CreatedAt).ToList();
        var items = ordered.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        return Task.FromResult(new VendorCreditActivityListResult(items, ordered.Count, page, pageSize));
    }

    public Task<VendorCreditActivity?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _activities.TryGetValue(id, out var activity);
        return Task.FromResult(activity);
    }

    public Task<VendorCreditActivity> AddAsync(VendorCreditActivity activity, CancellationToken cancellationToken = default)
    {
        _activities[activity.Id] = activity;
        return Task.FromResult(activity);
    }

    public Task<bool> MarkPostedAsync(Guid id, Guid? transactionId = null, CancellationToken cancellationToken = default)
    {
        if (!_activities.TryGetValue(id, out var activity)) return Task.FromResult(false);
        activity.MarkPosted(transactionId);
        return Task.FromResult(true);
    }
}
