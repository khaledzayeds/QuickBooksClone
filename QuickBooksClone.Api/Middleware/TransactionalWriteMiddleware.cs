using Microsoft.EntityFrameworkCore;
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

    public async Task InvokeAsync(HttpContext context, QuickBooksCloneDbContext dbContext)
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

            await transaction.CommitAsync(context.RequestAborted);
        }
        catch
        {
            await transaction.RollbackAsync(CancellationToken.None);
            throw;
        }
    }
}
