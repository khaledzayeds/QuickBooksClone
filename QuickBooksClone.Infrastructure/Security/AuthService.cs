using System.Security.Cryptography;
using System.Text;
using QuickBooksClone.Core.Security;

namespace QuickBooksClone.Infrastructure.Security;

public sealed class AuthService : IAuthService
{
    private static readonly TimeSpan SessionLifetime = TimeSpan.FromHours(12);

    private readonly ISecurityRepository _security;
    private readonly IPasswordHasher _passwordHasher;

    public AuthService(ISecurityRepository security, IPasswordHasher passwordHasher)
    {
        _security = security;
        _passwordHasher = passwordHasher;
    }

    public async Task<AuthResult> LoginAsync(string userName, string password, CancellationToken cancellationToken = default)
    {
        var user = await _security.GetUserByUserNameAsync(userName, cancellationToken);
        if (user is null || !user.IsActive || string.IsNullOrWhiteSpace(user.PasswordHash) || !_passwordHasher.Verify(password, user.PasswordHash))
        {
            throw new UnauthorizedAccessException("Invalid user name or password.");
        }

        var token = CreateToken();
        var expiresAt = DateTimeOffset.UtcNow.Add(SessionLifetime);
        var session = new SecuritySession(user.Id, HashToken(token), expiresAt);
        await _security.AddSessionAsync(session, cancellationToken);
        await _security.MarkUserLoginAsync(user.Id, cancellationToken);

        var refreshedUser = await _security.GetUserByIdAsync(user.Id, cancellationToken) ?? user;
        var permissions = await _security.GetEffectivePermissionsAsync(user.Id, cancellationToken);
        return new AuthResult(token, expiresAt, refreshedUser, permissions);
    }

    public async Task<AuthResult?> GetSessionAsync(string token, CancellationToken cancellationToken = default)
    {
        var session = await _security.GetActiveSessionByTokenHashAsync(HashToken(token), DateTimeOffset.UtcNow, cancellationToken);
        if (session is null)
        {
            return null;
        }

        var user = await _security.GetUserByIdAsync(session.UserId, cancellationToken);
        if (user is null || !user.IsActive)
        {
            return null;
        }

        var permissions = await _security.GetEffectivePermissionsAsync(user.Id, cancellationToken);
        return new AuthResult(token, session.ExpiresAt, user, permissions);
    }

    public Task<bool> LogoutAsync(string token, CancellationToken cancellationToken = default) =>
        _security.RevokeSessionAsync(HashToken(token), cancellationToken);

    public async Task<bool> SetPasswordAsync(Guid userId, string newPassword, CancellationToken cancellationToken = default)
    {
        var hash = _passwordHasher.HashPassword(newPassword);
        var updated = await _security.SetUserPasswordHashAsync(userId, hash, cancellationToken);
        if (updated)
        {
            await _security.RevokeUserSessionsAsync(userId, cancellationToken);
        }

        return updated;
    }

    public static string HashToken(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            throw new ArgumentException("Token is required.", nameof(token));
        }

        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(token.Trim()));
        return Convert.ToBase64String(hash);
    }

    private static string CreateToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(32);
        return Convert.ToBase64String(bytes);
    }
}
