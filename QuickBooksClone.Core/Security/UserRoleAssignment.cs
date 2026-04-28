using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Security;

public sealed class UserRoleAssignment : EntityBase
{
    private UserRoleAssignment()
    {
    }

    public UserRoleAssignment(Guid userId, Guid roleId)
    {
        UserId = userId == Guid.Empty ? throw new ArgumentException("User is required.", nameof(userId)) : userId;
        RoleId = roleId == Guid.Empty ? throw new ArgumentException("Role is required.", nameof(roleId)) : roleId;
    }

    public Guid UserId { get; private set; }
    public Guid RoleId { get; private set; }
}
