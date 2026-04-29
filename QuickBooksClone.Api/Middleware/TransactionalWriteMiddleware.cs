using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Security;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Middleware;

public sealed class TransactionalWriteMiddleware
{
    private static readonly PathString DatabaseMaintenancePath = new("/api/database");
    private static readonly HashSet<string> WriteMethods = new(StringComparer.OrdinalIgnoreCase)
    {
        HttpMethods.Post,
        HttpMethods.Put,
        HttpMethods.Patch,
        HttpMethods.Delete
    };

    private readonly RequestDelegate _next;

    public TransactionalWriteMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, QuickBooksCloneDbContext dbContext, IAuditLogRepository auditLog)
    {
        if (!WriteMethods.Contains(context.Request.Method) ||
            context.Request.Path.StartsWithSegments(DatabaseMaintenancePath, StringComparison.OrdinalIgnoreCase))
        {
            await _next(context);
            return;
        }

        await using var transaction = await dbContext.Database.BeginTransactionAsync(context.RequestAborted);

        try
        {
            await _next(context);

            if (context.Response.StatusCode >= StatusCodes.Status400BadRequest)
            {
                await transaction.RollbackAsync(context.RequestAborted);
                return;
            }

            await AddAuditEntryAsync(context, auditLog);
            await transaction.CommitAsync(context.RequestAborted);
        }
        catch
        {
            await transaction.RollbackAsync(CancellationToken.None);
            throw;
        }
    }

    private static async Task AddAuditEntryAsync(HttpContext context, IAuditLogRepository auditLog)
    {
        if (context.Items[PermissionAuthorizationMiddleware.CurrentUserItemKey] is not CurrentUserContext currentUser)
        {
            return;
        }

        var endpoint = context.GetEndpoint();
        var routeValues = context.Request.RouteValues;
        var controller = routeValues.TryGetValue("controller", out var controllerValue)
            ? controllerValue?.ToString()
            : null;
        var endpointAction = routeValues.TryGetValue("action", out var actionValue)
            ? actionValue?.ToString()
            : null;
        var requiredPermissions = endpoint?.Metadata
            .GetOrderedMetadata<RequirePermissionAttribute>()
            .Select(metadata => metadata.Permission)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(permission => permission, StringComparer.OrdinalIgnoreCase)
            .ToList();

        var auditAction = BuildAuditAction(context.Request.Method, controller, endpointAction);
        var path = context.Request.Path + context.Request.QueryString;

        var entry = new AuditLogEntry(
            currentUser.UserId,
            currentUser.UserName,
            auditAction,
            context.Request.Method,
            path,
            context.Response.StatusCode,
            controller,
            endpointAction,
            requiredPermissions is { Count: > 0 } ? string.Join(",", requiredPermissions) : null,
            context.Connection.RemoteIpAddress?.ToString(),
            context.Request.Headers.UserAgent.ToString());

        await auditLog.AddAsync(entry, context.RequestAborted);
    }

    private static string BuildAuditAction(string method, string? controller, string? endpointAction)
    {
        var normalizedController = string.IsNullOrWhiteSpace(controller) ? "Unknown" : controller;
        var normalizedAction = string.IsNullOrWhiteSpace(endpointAction)
            ? method.ToUpperInvariant()
            : endpointAction;
        return $"{normalizedController}.{normalizedAction}";
    }
}
