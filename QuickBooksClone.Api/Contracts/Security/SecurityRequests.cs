using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.Security;

public sealed record CreateSecurityRoleRequest(
    [Required, MaxLength(80)] string RoleKey,
    [Required, MaxLength(120)] string Name,
    [MaxLength(500)] string? Description,
    IReadOnlyList<string>? Permissions);

public sealed record UpdateSecurityRoleRequest(
    [Required, MaxLength(120)] string Name,
    [MaxLength(500)] string? Description);

public sealed record ReplaceRolePermissionsRequest(IReadOnlyList<string> Permissions);

public sealed record SetSecurityActiveRequest(bool IsActive);

public sealed record CreateSecurityUserRequest(
    [Required, MaxLength(80)] string UserName,
    [Required, MaxLength(160)] string DisplayName,
    [MaxLength(250)] string? Email,
    IReadOnlyList<Guid>? RoleIds);

public sealed record UpdateSecurityUserRequest(
    [Required, MaxLength(160)] string DisplayName,
    [MaxLength(250)] string? Email);

public sealed record ReplaceUserRolesRequest(IReadOnlyList<Guid> RoleIds);
