namespace Zayed.Api.Security;

public sealed record CurrentUserContext(
    Guid UserId,
    string UserName,
    string DisplayName,
    IReadOnlyCollection<string> Permissions);
