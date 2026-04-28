using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Security;

public sealed class SecuritySession : EntityBase, ITenantEntity
{
    public static readonly Guid DefaultCompanyId = Guid.Parse("11111111-1111-1111-1111-111111111111");

    private SecuritySession()
    {
        CompanyId = Guid.Empty;
        TokenHash = string.Empty;
    }

    public SecuritySession(Guid userId, string tokenHash, DateTimeOffset expiresAt, Guid? companyId = null)
    {
        if (userId == Guid.Empty)
        {
            throw new ArgumentException("User is required.", nameof(userId));
        }

        CompanyId = companyId ?? DefaultCompanyId;
        UserId = userId;
        TokenHash = SecurityRole.NormalizeRequired(tokenHash, nameof(tokenHash), 500);
        ExpiresAt = expiresAt <= DateTimeOffset.UtcNow
            ? throw new ArgumentOutOfRangeException(nameof(expiresAt), "Session expiry must be in the future.")
            : expiresAt;
        IsRevoked = false;
    }

    public Guid CompanyId { get; }
    public Guid UserId { get; private set; }
    public string TokenHash { get; private set; }
    public DateTimeOffset ExpiresAt { get; private set; }
    public DateTimeOffset? RevokedAt { get; private set; }
    public bool IsRevoked { get; private set; }

    public bool IsActive(DateTimeOffset now) => !IsRevoked && ExpiresAt > now;

    public void Revoke()
    {
        if (IsRevoked)
        {
            return;
        }

        IsRevoked = true;
        RevokedAt = DateTimeOffset.UtcNow;
        UpdatedAt = RevokedAt;
    }
}
