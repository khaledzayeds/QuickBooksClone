using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Security;

public sealed class SecurityRole : EntityBase, ITenantEntity
{
    public static readonly Guid DefaultCompanyId = Guid.Parse("11111111-1111-1111-1111-111111111111");

    private readonly List<RolePermission> _permissions = [];

    private SecurityRole()
    {
        CompanyId = Guid.Empty;
        RoleKey = string.Empty;
        Name = string.Empty;
    }

    public SecurityRole(string roleKey, string name, string? description, bool isSystem = false, Guid? companyId = null)
    {
        CompanyId = companyId ?? DefaultCompanyId;
        RoleKey = PermissionCatalog.NormalizeRoleKey(roleKey);
        Name = NormalizeRequired(name, nameof(name), 120);
        Description = NormalizeOptional(description, 500);
        IsSystem = isSystem;
        IsActive = true;
    }

    public Guid CompanyId { get; }
    public string RoleKey { get; private set; }
    public string Name { get; private set; }
    public string? Description { get; private set; }
    public bool IsSystem { get; private set; }
    public bool IsActive { get; private set; }
    public IReadOnlyList<RolePermission> Permissions => _permissions;

    public void Update(string name, string? description)
    {
        Name = NormalizeRequired(name, nameof(name), 120);
        Description = NormalizeOptional(description, 500);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SetActive(bool isActive)
    {
        if (IsSystem && !isActive)
        {
            throw new InvalidOperationException("System roles cannot be deactivated.");
        }

        IsActive = isActive;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ReplacePermissions(IEnumerable<string> permissions)
    {
        var normalized = PermissionCatalog.NormalizeMany(permissions);
        _permissions.Clear();
        _permissions.AddRange(normalized.Select(permission => new RolePermission(Id, permission)));
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public static string NormalizeRequired(string value, string parameterName, int maxLength)
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

    public static string? NormalizeOptional(string? value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var normalized = value.Trim();
        if (normalized.Length > maxLength)
        {
            throw new ArgumentOutOfRangeException(nameof(value), $"Value must be {maxLength} characters or fewer.");
        }

        return normalized;
    }
}
