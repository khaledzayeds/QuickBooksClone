using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Security;

public sealed class RolePermission : EntityBase
{
    private RolePermission()
    {
        Permission = string.Empty;
    }

    public RolePermission(Guid roleId, string permission)
    {
        RoleId = roleId == Guid.Empty ? throw new ArgumentException("Role is required.", nameof(roleId)) : roleId;
        Permission = PermissionCatalog.NormalizeMany([permission]).Single();
    }

    public Guid RoleId { get; private set; }
    public string Permission { get; private set; }
}
