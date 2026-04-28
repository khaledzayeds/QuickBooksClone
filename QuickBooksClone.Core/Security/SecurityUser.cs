using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Security;

public sealed class SecurityUser : EntityBase, ITenantEntity
{
    public static readonly Guid DefaultCompanyId = Guid.Parse("11111111-1111-1111-1111-111111111111");

    private readonly List<UserRoleAssignment> _roleAssignments = [];

    private SecurityUser()
    {
        CompanyId = Guid.Empty;
        UserName = string.Empty;
        DisplayName = string.Empty;
    }

    public SecurityUser(string userName, string displayName, string? email, string? passwordHash = null, Guid? companyId = null)
    {
        CompanyId = companyId ?? DefaultCompanyId;
        UserName = NormalizeUserName(userName);
        DisplayName = SecurityRole.NormalizeRequired(displayName, nameof(displayName), 160);
        Email = NormalizeEmail(email);
        PasswordHash = SecurityRole.NormalizeOptional(passwordHash, 500);
        IsActive = true;
    }

    public Guid CompanyId { get; }
    public string UserName { get; private set; }
    public string DisplayName { get; private set; }
    public string? Email { get; private set; }
    public string? PasswordHash { get; private set; }
    public bool IsActive { get; private set; }
    public DateTimeOffset? LastLoginAt { get; private set; }
    public IReadOnlyList<UserRoleAssignment> RoleAssignments => _roleAssignments;

    public void Update(string displayName, string? email)
    {
        DisplayName = SecurityRole.NormalizeRequired(displayName, nameof(displayName), 160);
        Email = NormalizeEmail(email);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SetPasswordHash(string passwordHash)
    {
        PasswordHash = SecurityRole.NormalizeRequired(passwordHash, nameof(passwordHash), 500);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SetActive(bool isActive)
    {
        IsActive = isActive;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkLogin()
    {
        LastLoginAt = DateTimeOffset.UtcNow;
        UpdatedAt = LastLoginAt;
    }

    public void ReplaceRoles(IEnumerable<Guid> roleIds)
    {
        var normalized = roleIds
            .Where(id => id != Guid.Empty)
            .Distinct()
            .ToList();

        _roleAssignments.Clear();
        _roleAssignments.AddRange(normalized.Select(roleId => new UserRoleAssignment(Id, roleId)));
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public static string NormalizeUserName(string userName)
    {
        if (string.IsNullOrWhiteSpace(userName))
        {
            throw new ArgumentException("User name is required.", nameof(userName));
        }

        var normalized = userName.Trim().ToLowerInvariant();
        if (normalized.Length > 80)
        {
            throw new ArgumentOutOfRangeException(nameof(userName), "User name must be 80 characters or fewer.");
        }

        return normalized;
    }

    private static string? NormalizeEmail(string? email)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            return null;
        }

        var normalized = email.Trim().ToLowerInvariant();
        if (normalized.Length > 250)
        {
            throw new ArgumentOutOfRangeException(nameof(email), "Email must be 250 characters or fewer.");
        }

        return normalized;
    }
}
