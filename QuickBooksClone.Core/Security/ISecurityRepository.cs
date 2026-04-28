namespace QuickBooksClone.Core.Security;

public interface ISecurityRepository
{
    Task<SecurityRoleListResult> SearchRolesAsync(SecurityRoleSearch search, CancellationToken cancellationToken = default);
    Task<SecurityRole?> GetRoleByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<SecurityRole?> GetRoleByKeyAsync(string roleKey, CancellationToken cancellationToken = default);
    Task<bool> RoleKeyExistsAsync(string roleKey, Guid? excludingId = null, CancellationToken cancellationToken = default);
    Task<SecurityRole> AddRoleAsync(SecurityRole role, CancellationToken cancellationToken = default);
    Task<SecurityRole?> UpdateRoleAsync(Guid id, string name, string? description, CancellationToken cancellationToken = default);
    Task<bool> SetRoleActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default);
    Task<SecurityRole?> ReplaceRolePermissionsAsync(Guid id, IEnumerable<string> permissions, CancellationToken cancellationToken = default);

    Task<SecurityUserListResult> SearchUsersAsync(SecurityUserSearch search, CancellationToken cancellationToken = default);
    Task<SecurityUser?> GetUserByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<SecurityUser?> GetUserByUserNameAsync(string userName, CancellationToken cancellationToken = default);
    Task<bool> UserNameExistsAsync(string userName, Guid? excludingId = null, CancellationToken cancellationToken = default);
    Task<bool> UserEmailExistsAsync(string email, Guid? excludingId = null, CancellationToken cancellationToken = default);
    Task<SecurityUser> AddUserAsync(SecurityUser user, IEnumerable<Guid> roleIds, CancellationToken cancellationToken = default);
    Task<SecurityUser?> UpdateUserAsync(Guid id, string displayName, string? email, CancellationToken cancellationToken = default);
    Task<bool> SetUserActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default);
    Task<SecurityUser?> ReplaceUserRolesAsync(Guid id, IEnumerable<Guid> roleIds, CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<string>> GetEffectivePermissionsAsync(Guid userId, CancellationToken cancellationToken = default);
}
