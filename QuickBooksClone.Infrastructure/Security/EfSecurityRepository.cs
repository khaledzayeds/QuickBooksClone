using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Security;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Infrastructure.Security;

public sealed class EfSecurityRepository : ISecurityRepository
{
    private readonly QuickBooksCloneDbContext _db;

    public EfSecurityRepository(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    public async Task<SecurityRoleListResult> SearchRolesAsync(SecurityRoleSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = RoleQuery();

        if (!search.IncludeInactive)
        {
            query = query.Where(role => role.IsActive);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = EfAccountRepository.Like(search.Search);
            query = query.Where(role => EF.Functions.Like(role.RoleKey, term) || EF.Functions.Like(role.Name, term));
        }

        var total = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderBy(role => role.RoleKey)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new SecurityRoleListResult(items, total, page, pageSize);
    }

    public Task<SecurityRole?> GetRoleByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        RoleQuery().FirstOrDefaultAsync(role => role.Id == id, cancellationToken);

    public Task<SecurityRole?> GetRoleByKeyAsync(string roleKey, CancellationToken cancellationToken = default)
    {
        var normalized = PermissionCatalog.NormalizeRoleKey(roleKey);
        return RoleQuery().FirstOrDefaultAsync(role => role.RoleKey == normalized, cancellationToken);
    }

    public Task<bool> RoleKeyExistsAsync(string roleKey, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        var normalized = PermissionCatalog.NormalizeRoleKey(roleKey);
        return _db.SecurityRoles.AnyAsync(role => role.Id != excludingId && role.RoleKey == normalized, cancellationToken);
    }

    public async Task<SecurityRole> AddRoleAsync(SecurityRole role, CancellationToken cancellationToken = default)
    {
        _db.SecurityRoles.Add(role);
        await _db.SaveChangesAsync(cancellationToken);
        return role;
    }

    public async Task<SecurityRole?> UpdateRoleAsync(Guid id, string name, string? description, CancellationToken cancellationToken = default)
    {
        var role = await GetRoleByIdAsync(id, cancellationToken);
        if (role is null)
        {
            return null;
        }

        role.Update(name, description);
        await _db.SaveChangesAsync(cancellationToken);
        return role;
    }

    public async Task<bool> SetRoleActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default)
    {
        var role = await GetRoleByIdAsync(id, cancellationToken);
        if (role is null)
        {
            return false;
        }

        role.SetActive(isActive);
        await _db.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<SecurityRole?> ReplaceRolePermissionsAsync(Guid id, IEnumerable<string> permissions, CancellationToken cancellationToken = default)
    {
        var role = await GetRoleByIdAsync(id, cancellationToken);
        if (role is null)
        {
            return null;
        }

        role.ReplacePermissions(permissions);
        await _db.SaveChangesAsync(cancellationToken);
        return role;
    }

    public async Task<SecurityUserListResult> SearchUsersAsync(SecurityUserSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = UserQuery();

        if (!search.IncludeInactive)
        {
            query = query.Where(user => user.IsActive);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = EfAccountRepository.Like(search.Search);
            query = query.Where(user =>
                EF.Functions.Like(user.UserName, term) ||
                EF.Functions.Like(user.DisplayName, term) ||
                (user.Email != null && EF.Functions.Like(user.Email, term)));
        }

        var total = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderBy(user => user.UserName)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new SecurityUserListResult(items, total, page, pageSize);
    }

    public Task<SecurityUser?> GetUserByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        UserQuery().FirstOrDefaultAsync(user => user.Id == id, cancellationToken);

    public Task<SecurityUser?> GetUserByUserNameAsync(string userName, CancellationToken cancellationToken = default)
    {
        var normalized = SecurityUser.NormalizeUserName(userName);
        return UserQuery().FirstOrDefaultAsync(user => user.UserName == normalized, cancellationToken);
    }

    public Task<bool> UserNameExistsAsync(string userName, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        var normalized = SecurityUser.NormalizeUserName(userName);
        return _db.SecurityUsers.AnyAsync(user => user.Id != excludingId && user.UserName == normalized, cancellationToken);
    }

    public Task<bool> UserEmailExistsAsync(string email, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        var normalized = email.Trim().ToLowerInvariant();
        return _db.SecurityUsers.AnyAsync(user => user.Id != excludingId && user.Email == normalized, cancellationToken);
    }

    public async Task<SecurityUser> AddUserAsync(SecurityUser user, IEnumerable<Guid> roleIds, CancellationToken cancellationToken = default)
    {
        var normalizedRoleIds = await EnsureRolesExistAsync(roleIds, cancellationToken);
        _db.SecurityUsers.Add(user);
        await _db.SaveChangesAsync(cancellationToken);

        await ReplaceUserRoleRowsAsync(user.Id, normalizedRoleIds, cancellationToken);
        return await GetUserByIdAsync(user.Id, cancellationToken) ?? user;
    }

    public async Task<SecurityUser?> UpdateUserAsync(Guid id, string displayName, string? email, CancellationToken cancellationToken = default)
    {
        var user = await GetUserByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return null;
        }

        user.Update(displayName, email);
        await _db.SaveChangesAsync(cancellationToken);
        return user;
    }

    public async Task<bool> SetUserActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default)
    {
        var user = await GetUserByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return false;
        }

        user.SetActive(isActive);
        await _db.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<SecurityUser?> ReplaceUserRolesAsync(Guid id, IEnumerable<Guid> roleIds, CancellationToken cancellationToken = default)
    {
        var user = await GetUserByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return null;
        }

        var normalizedRoleIds = await EnsureRolesExistAsync(roleIds, cancellationToken);
        await ReplaceUserRoleRowsAsync(user.Id, normalizedRoleIds, cancellationToken);
        return await GetUserByIdAsync(id, cancellationToken);
    }

    public async Task<IReadOnlyCollection<string>> GetEffectivePermissionsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var user = await GetUserByIdAsync(userId, cancellationToken);
        if (user is null || !user.IsActive)
        {
            return [];
        }

        var roleIds = user.RoleAssignments.Select(assignment => assignment.RoleId).ToList();
        return await _db.RolePermissions
            .Where(permission => roleIds.Contains(permission.RoleId))
            .Join(_db.SecurityRoles.Where(role => role.IsActive), permission => permission.RoleId, role => role.Id, (permission, _) => permission.Permission)
            .Distinct()
            .OrderBy(permission => permission)
            .ToListAsync(cancellationToken);
    }

    private IQueryable<SecurityRole> RoleQuery() => _db.SecurityRoles.Include(role => role.Permissions);

    private IQueryable<SecurityUser> UserQuery() => _db.SecurityUsers.Include(user => user.RoleAssignments);

    private async Task<IReadOnlyList<Guid>> EnsureRolesExistAsync(IEnumerable<Guid> roleIds, CancellationToken cancellationToken)
    {
        var normalized = roleIds.Where(id => id != Guid.Empty).Distinct().ToList();
        var count = await _db.SecurityRoles.CountAsync(role => normalized.Contains(role.Id) && role.IsActive, cancellationToken);
        if (count != normalized.Count)
        {
            throw new ArgumentException("One or more roles do not exist or are inactive.", nameof(roleIds));
        }

        return normalized;
    }

    private async Task ReplaceUserRoleRowsAsync(Guid userId, IReadOnlyList<Guid> roleIds, CancellationToken cancellationToken)
    {
        var existing = await _db.UserRoleAssignments
            .Where(assignment => assignment.UserId == userId)
            .ToListAsync(cancellationToken);

        _db.UserRoleAssignments.RemoveRange(existing);
        _db.UserRoleAssignments.AddRange(roleIds.Select(roleId => new UserRoleAssignment(userId, roleId)));
        await _db.SaveChangesAsync(cancellationToken);
    }
}
