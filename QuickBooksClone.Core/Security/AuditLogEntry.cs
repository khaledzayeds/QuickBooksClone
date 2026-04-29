using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Security;

public sealed class AuditLogEntry : EntityBase, ITenantEntity
{
    public static readonly Guid DefaultCompanyId = Guid.Parse("11111111-1111-1111-1111-111111111111");

    private AuditLogEntry()
    {
        CompanyId = Guid.Empty;
        UserName = string.Empty;
        Action = string.Empty;
        HttpMethod = string.Empty;
        Path = string.Empty;
    }

    public AuditLogEntry(
        Guid? userId,
        string? userName,
        string action,
        string httpMethod,
        string path,
        int statusCode,
        string? controller,
        string? endpointAction,
        string? requiredPermissions,
        string? ipAddress,
        string? userAgent,
        Guid? companyId = null)
    {
        CompanyId = companyId ?? DefaultCompanyId;
        UserId = userId;
        UserName = NormalizeOptional(userName, 160) ?? "anonymous";
        Action = NormalizeRequired(action, nameof(action), 160);
        HttpMethod = NormalizeRequired(httpMethod, nameof(httpMethod), 20);
        Path = NormalizeRequired(path, nameof(path), 500);
        StatusCode = statusCode;
        Controller = NormalizeOptional(controller, 160);
        EndpointAction = NormalizeOptional(endpointAction, 160);
        RequiredPermissions = NormalizeOptional(requiredPermissions, 1000);
        IpAddress = NormalizeOptional(ipAddress, 80);
        UserAgent = NormalizeOptional(userAgent, 500);
        OccurredAt = DateTimeOffset.UtcNow;
    }

    public Guid CompanyId { get; }
    public Guid? UserId { get; private set; }
    public string UserName { get; private set; }
    public string Action { get; private set; }
    public string HttpMethod { get; private set; }
    public string Path { get; private set; }
    public int StatusCode { get; private set; }
    public string? Controller { get; private set; }
    public string? EndpointAction { get; private set; }
    public string? RequiredPermissions { get; private set; }
    public string? IpAddress { get; private set; }
    public string? UserAgent { get; private set; }
    public DateTimeOffset OccurredAt { get; private set; }

    private static string NormalizeRequired(string value, string parameterName, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Value is required.", parameterName);
        }

        var normalized = value.Trim();
        if (normalized.Length > maxLength)
        {
            throw new ArgumentOutOfRangeException(parameterName, $"Value must be {maxLength} characters or fewer.");
        }

        return normalized;
    }

    private static string? NormalizeOptional(string? value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var normalized = value.Trim();
        return normalized.Length <= maxLength ? normalized : normalized[..maxLength];
    }
}
