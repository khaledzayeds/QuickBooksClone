namespace QuickBooksClone.Core.Security;

public interface IAuthService
{
    Task<AuthResult> LoginAsync(string userName, string password, CancellationToken cancellationToken = default);
    Task<AuthResult?> GetSessionAsync(string token, CancellationToken cancellationToken = default);
    Task<bool> LogoutAsync(string token, CancellationToken cancellationToken = default);
    Task<bool> SetPasswordAsync(Guid userId, string newPassword, CancellationToken cancellationToken = default);
}

public sealed record AuthResult(
    string Token,
    DateTimeOffset ExpiresAt,
    SecurityUser User,
    IReadOnlyCollection<string> EffectivePermissions);
