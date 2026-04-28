using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.Security;

public sealed record LoginRequest(
    [Required, MaxLength(80)] string UserName,
    [Required, MaxLength(200)] string Password);

public sealed record AuthResponse(
    string Token,
    DateTimeOffset ExpiresAt,
    SecurityUserDto User);

public sealed record SetPasswordRequest(
    [Required, MinLength(4), MaxLength(200)] string NewPassword);
