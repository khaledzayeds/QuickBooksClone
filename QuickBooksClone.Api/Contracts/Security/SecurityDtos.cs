namespace QuickBooksClone.Api.Contracts.Security;

public sealed record PermissionDto(string Key, string Area, string Name, string Description);

public sealed record SecurityRoleDto(
    Guid Id,
    string RoleKey,
    string Name,
    string? Description,
    bool IsSystem,
    bool IsActive,
    IReadOnlyList<string> Permissions);

public sealed record SecurityRoleListResponse(IReadOnlyList<SecurityRoleDto> Items, int TotalCount, int Page, int PageSize);

public sealed record SecurityUserRoleDto(Guid Id, string RoleKey, string Name);

public sealed record SecurityUserDto(
    Guid Id,
    string UserName,
    string DisplayName,
    string? Email,
    bool IsActive,
    DateTimeOffset? LastLoginAt,
    IReadOnlyList<SecurityUserRoleDto> Roles,
    IReadOnlyList<string> EffectivePermissions);

public sealed record SecurityUserListResponse(IReadOnlyList<SecurityUserDto> Items, int TotalCount, int Page, int PageSize);
