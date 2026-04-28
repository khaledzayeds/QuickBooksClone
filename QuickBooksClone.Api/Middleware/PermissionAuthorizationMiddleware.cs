using Microsoft.AspNetCore.Authorization;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Security;

namespace QuickBooksClone.Api.Middleware;

public sealed class PermissionAuthorizationMiddleware
{
    public const string CurrentUserItemKey = "QuickBooksClone.CurrentUser";

    private readonly RequestDelegate _next;

    public PermissionAuthorizationMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, IAuthService authService)
    {
        var endpoint = context.GetEndpoint();
        if (endpoint is null || endpoint.Metadata.GetMetadata<IAllowAnonymous>() is not null)
        {
            await _next(context);
            return;
        }

        var requiredPermissions = endpoint.Metadata
            .GetOrderedMetadata<RequirePermissionAttribute>()
            .Select(metadata => metadata.Permission)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        var requiresAuthenticatedUser = endpoint.Metadata.GetMetadata<RequireAuthenticatedAttribute>() is not null;
        if (!requiresAuthenticatedUser && requiredPermissions.Count == 0)
        {
            await _next(context);
            return;
        }

        var token = ReadBearerToken(context);
        if (token is null)
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Authentication token is required.");
            return;
        }

        var session = await authService.GetSessionAsync(token, context.RequestAborted);
        if (session is null)
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Authentication session is invalid or expired.");
            return;
        }

        var permissions = session.EffectivePermissions.ToHashSet(StringComparer.OrdinalIgnoreCase);
        var missingPermission = requiredPermissions.FirstOrDefault(permission => !permissions.Contains(permission));
        if (missingPermission is not null)
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            await context.Response.WriteAsync($"Missing permission: {missingPermission}.");
            return;
        }

        context.Items[CurrentUserItemKey] = new CurrentUserContext(
            session.User.Id,
            session.User.UserName,
            session.User.DisplayName,
            session.EffectivePermissions.ToList());

        await _next(context);
    }

    private static string? ReadBearerToken(HttpContext context)
    {
        var authorization = context.Request.Headers.Authorization.ToString();
        const string prefix = "Bearer ";
        if (!authorization.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var token = authorization[prefix.Length..].Trim();
        return string.IsNullOrWhiteSpace(token) ? null : token;
    }
}
