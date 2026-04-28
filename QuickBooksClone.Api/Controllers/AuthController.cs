using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Security;
using QuickBooksClone.Core.Security;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController : ControllerBase
{
    private readonly IAuthService _auth;
    private readonly ISecurityRepository _security;

    public AuthController(IAuthService auth, ISecurityRepository security)
    {
        _auth = auth;
        _security = security;
    }

    [HttpPost("login")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _auth.LoginAsync(request.UserName, request.Password, cancellationToken);
            return Ok(await ToResponseAsync(result, cancellationToken));
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized("Invalid user name or password.");
        }
    }

    [HttpGet("me")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthResponse>> Me(CancellationToken cancellationToken = default)
    {
        var token = ReadBearerToken();
        if (token is null)
        {
            return Unauthorized();
        }

        var result = await _auth.GetSessionAsync(token, cancellationToken);
        return result is null ? Unauthorized() : Ok(await ToResponseAsync(result, cancellationToken));
    }

    [HttpPost("logout")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Logout(CancellationToken cancellationToken = default)
    {
        var token = ReadBearerToken();
        if (token is not null)
        {
            await _auth.LogoutAsync(token, cancellationToken);
        }

        return NoContent();
    }

    [HttpPut("users/{id:guid}/password")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetPassword(Guid id, SetPasswordRequest request, CancellationToken cancellationToken = default)
    {
        var updated = await _auth.SetPasswordAsync(id, request.NewPassword, cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    private string? ReadBearerToken()
    {
        var authorization = Request.Headers.Authorization.ToString();
        const string prefix = "Bearer ";
        if (!authorization.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var token = authorization[prefix.Length..].Trim();
        return string.IsNullOrWhiteSpace(token) ? null : token;
    }

    private async Task<AuthResponse> ToResponseAsync(AuthResult result, CancellationToken cancellationToken)
    {
        var user = result.User;
        var roles = new List<SecurityUserRoleDto>();
        foreach (var assignment in user.RoleAssignments)
        {
            var role = await _security.GetRoleByIdAsync(assignment.RoleId, cancellationToken);
            if (role is not null)
            {
                roles.Add(new SecurityUserRoleDto(role.Id, role.RoleKey, role.Name));
            }
        }

        var userDto = new SecurityUserDto(
            user.Id,
            user.UserName,
            user.DisplayName,
            user.Email,
            user.IsActive,
            user.LastLoginAt,
            roles.OrderBy(role => role.RoleKey).ToList(),
            result.EffectivePermissions.OrderBy(permission => permission).ToList());

        return new AuthResponse(result.Token, result.ExpiresAt, userDto);
    }
}
