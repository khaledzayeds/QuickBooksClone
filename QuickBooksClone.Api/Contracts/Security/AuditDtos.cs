namespace QuickBooksClone.Api.Contracts.Security;

public sealed record AuditLogEntryDto(
    Guid Id,
    Guid? UserId,
    string UserName,
    string Action,
    string HttpMethod,
    string Path,
    int StatusCode,
    string? Controller,
    string? EndpointAction,
    string? RequiredPermissions,
    string? IpAddress,
    string? UserAgent,
    DateTimeOffset OccurredAt);

public sealed record AuditLogListResponse(
    IReadOnlyList<AuditLogEntryDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
