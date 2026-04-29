namespace QuickBooksClone.Core.Security;

public interface IAuditLogRepository
{
    Task AddAsync(AuditLogEntry entry, CancellationToken cancellationToken = default);
    Task<AuditLogSearchResult> SearchAsync(AuditLogSearch search, CancellationToken cancellationToken = default);
}

public sealed record AuditLogSearch(
    Guid? UserId,
    string? UserName,
    string? Action,
    string? Controller,
    DateTimeOffset? From,
    DateTimeOffset? To,
    int Page = 1,
    int PageSize = 50);

public sealed record AuditLogSearchResult(IReadOnlyList<AuditLogEntry> Items, int TotalCount, int Page, int PageSize);
