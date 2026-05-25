using System.ComponentModel.DataAnnotations;

namespace Zayed.Api.Contracts.Security;

public sealed record LoginRequest(
    [Required, MaxLength(80)] string UserName,
    [Required, MaxLength(200)] string Password);

public sealed record AuthResponse(
    string Token,
    DateTimeOffset ExpiresAt,
    SecurityUserDto User);

public sealed record LoginUserOptionDto(
    Guid Id,
    string UserName,
    string DisplayName,
    IReadOnlyList<string> Roles);

public sealed record SetPasswordRequest(
    [Required, MinLength(4), MaxLength(200)] string NewPassword);
