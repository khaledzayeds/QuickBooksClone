using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Security;
using QuickBooksClone.Core.Security;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/security")]
public sealed class SecurityController : ControllerBase
{
    private readonly ISecurityRepository _security;

    public SecurityController(ISecurityRepository security)
    {
        _security = security;
    }

    [HttpGet("permissions")]
    [ProducesResponseType(typeof(IReadOnlyList<PermissionDto>), StatusCodes.Status200OK)]
    public ActionResult<IReadOnlyList<PermissionDto>> GetPermissions()
    {
        return Ok(PermissionCatalog.All.Select(permission =>
            new PermissionDto(permission.Key, permission.Area, permission.Name, permission.Description)).ToList());
    }

    [HttpGet("roles")]
    [ProducesResponseType(typeof(SecurityRoleListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<SecurityRoleListResponse>> SearchRoles(
        [FromQuery] string? search,
        [FromQuery] bool includeInactive = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _security.SearchRolesAsync(new SecurityRoleSearch(search, includeInactive, page, pageSize), cancellationToken);
        return Ok(new SecurityRoleListResponse(result.Items.Select(ToRoleDto).ToList(), result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("roles/{id:guid}")]
    [ProducesResponseType(typeof(SecurityRoleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SecurityRoleDto>> GetRole(Guid id, CancellationToken cancellationToken = default)
    {
        var role = await _security.GetRoleByIdAsync(id, cancellationToken);
        return role is null ? NotFound() : Ok(ToRoleDto(role));
    }

    [HttpPost("roles")]
    [ProducesResponseType(typeof(SecurityRoleDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<SecurityRoleDto>> CreateRole(CreateSecurityRoleRequest request, CancellationToken cancellationToken = default)
    {
        if (await _security.RoleKeyExistsAsync(request.RoleKey, null, cancellationToken))
        {
            return Conflict("Role key already exists.");
        }

        try
        {
            var role = new SecurityRole(request.RoleKey, request.Name, request.Description);
            role.ReplacePermissions(request.Permissions ?? []);
            await _security.AddRoleAsync(role, cancellationToken);
            return CreatedAtAction(nameof(GetRole), new { id = role.Id }, ToRoleDto(role));
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPut("roles/{id:guid}")]
    [ProducesResponseType(typeof(SecurityRoleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SecurityRoleDto>> UpdateRole(Guid id, UpdateSecurityRoleRequest request, CancellationToken cancellationToken = default)
    {
        var role = await _security.UpdateRoleAsync(id, request.Name, request.Description, cancellationToken);
        return role is null ? NotFound() : Ok(ToRoleDto(role));
    }

    [HttpPatch("roles/{id:guid}/active")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetRoleActive(Guid id, SetSecurityActiveRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var updated = await _security.SetRoleActiveAsync(id, request.IsActive, cancellationToken);
            return updated ? NoContent() : NotFound();
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPut("roles/{id:guid}/permissions")]
    [ProducesResponseType(typeof(SecurityRoleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SecurityRoleDto>> ReplaceRolePermissions(Guid id, ReplaceRolePermissionsRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var role = await _security.ReplaceRolePermissionsAsync(id, request.Permissions, cancellationToken);
            return role is null ? NotFound() : Ok(ToRoleDto(role));
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpGet("users")]
    [ProducesResponseType(typeof(SecurityUserListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<SecurityUserListResponse>> SearchUsers(
        [FromQuery] string? search,
        [FromQuery] bool includeInactive = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _security.SearchUsersAsync(new SecurityUserSearch(search, includeInactive, page, pageSize), cancellationToken);
        var items = new List<SecurityUserDto>();
        foreach (var user in result.Items)
        {
            items.Add(await ToUserDtoAsync(user, cancellationToken));
        }

        return Ok(new SecurityUserListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("users/{id:guid}")]
    [ProducesResponseType(typeof(SecurityUserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SecurityUserDto>> GetUser(Guid id, CancellationToken cancellationToken = default)
    {
        var user = await _security.GetUserByIdAsync(id, cancellationToken);
        return user is null ? NotFound() : Ok(await ToUserDtoAsync(user, cancellationToken));
    }

    [HttpPost("users")]
    [ProducesResponseType(typeof(SecurityUserDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<SecurityUserDto>> CreateUser(CreateSecurityUserRequest request, CancellationToken cancellationToken = default)
    {
        if (await _security.UserNameExistsAsync(request.UserName, null, cancellationToken))
        {
            return Conflict("User name already exists.");
        }

        if (!string.IsNullOrWhiteSpace(request.Email) && await _security.UserEmailExistsAsync(request.Email, null, cancellationToken))
        {
            return Conflict("User email already exists.");
        }

        try
        {
            var user = new SecurityUser(request.UserName, request.DisplayName, request.Email);
            await _security.AddUserAsync(user, request.RoleIds ?? [], cancellationToken);
            return CreatedAtAction(nameof(GetUser), new { id = user.Id }, await ToUserDtoAsync(user, cancellationToken));
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPut("users/{id:guid}")]
    [ProducesResponseType(typeof(SecurityUserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<SecurityUserDto>> UpdateUser(Guid id, UpdateSecurityUserRequest request, CancellationToken cancellationToken = default)
    {
        if (!string.IsNullOrWhiteSpace(request.Email) && await _security.UserEmailExistsAsync(request.Email, id, cancellationToken))
        {
            return Conflict("User email already exists.");
        }

        var user = await _security.UpdateUserAsync(id, request.DisplayName, request.Email, cancellationToken);
        return user is null ? NotFound() : Ok(await ToUserDtoAsync(user, cancellationToken));
    }

    [HttpPatch("users/{id:guid}/active")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetUserActive(Guid id, SetSecurityActiveRequest request, CancellationToken cancellationToken = default)
    {
        var updated = await _security.SetUserActiveAsync(id, request.IsActive, cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    [HttpPut("users/{id:guid}/roles")]
    [ProducesResponseType(typeof(SecurityUserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SecurityUserDto>> ReplaceUserRoles(Guid id, ReplaceUserRolesRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var user = await _security.ReplaceUserRolesAsync(id, request.RoleIds, cancellationToken);
            return user is null ? NotFound() : Ok(await ToUserDtoAsync(user, cancellationToken));
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    private static SecurityRoleDto ToRoleDto(SecurityRole role) =>
        new(
            role.Id,
            role.RoleKey,
            role.Name,
            role.Description,
            role.IsSystem,
            role.IsActive,
            role.Permissions.Select(permission => permission.Permission).OrderBy(permission => permission).ToList());

    private async Task<SecurityUserDto> ToUserDtoAsync(SecurityUser user, CancellationToken cancellationToken)
    {
        var roles = new List<SecurityUserRoleDto>();
        foreach (var assignment in user.RoleAssignments)
        {
            var role = await _security.GetRoleByIdAsync(assignment.RoleId, cancellationToken);
            if (role is not null)
            {
                roles.Add(new SecurityUserRoleDto(role.Id, role.RoleKey, role.Name));
            }
        }

        var effectivePermissions = await _security.GetEffectivePermissionsAsync(user.Id, cancellationToken);
        return new SecurityUserDto(
            user.Id,
            user.UserName,
            user.DisplayName,
            user.Email,
            user.IsActive,
            user.LastLoginAt,
            roles.OrderBy(role => role.RoleKey).ToList(),
            effectivePermissions.ToList());
    }
}
