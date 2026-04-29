using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Security;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Infrastructure.Security;

public sealed class EfAuditLogRepository : IAuditLogRepository
{
    private readonly QuickBooksCloneDbContext _dbContext;

    public EfAuditLogRepository(QuickBooksCloneDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task AddAsync(AuditLogEntry entry, CancellationToken cancellationToken = default)
    {
        _dbContext.AuditLogEntries.Add(entry);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<AuditLogSearchResult> SearchAsync(AuditLogSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(1, search.Page);
        var pageSize = Math.Clamp(search.PageSize, 1, 200);

        var query = _dbContext.AuditLogEntries.AsNoTracking().AsQueryable();

        if (search.UserId is Guid userId)
        {
            query = query.Where(entry => entry.UserId == userId);
        }

        if (!string.IsNullOrWhiteSpace(search.UserName))
        {
            var userName = search.UserName.Trim();
            query = query.Where(entry => entry.UserName.Contains(userName));
        }

        if (!string.IsNullOrWhiteSpace(search.Action))
        {
            var action = search.Action.Trim();
            query = query.Where(entry => entry.Action.Contains(action));
        }

        if (!string.IsNullOrWhiteSpace(search.Controller))
        {
            var controller = search.Controller.Trim();
            query = query.Where(entry => entry.Controller == controller);
        }

        if (search.From is DateTimeOffset from)
        {
            query = query.Where(entry => entry.OccurredAt >= from);
        }

        if (search.To is DateTimeOffset to)
        {
            query = query.Where(entry => entry.OccurredAt <= to);
        }

        var filteredItems = await query.ToListAsync(cancellationToken);
        var totalCount = filteredItems.Count;
        var items = filteredItems
            .OrderByDescending(entry => entry.OccurredAt)
            .ThenByDescending(entry => entry.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return new AuditLogSearchResult(items, totalCount, page, pageSize);
    }
}
