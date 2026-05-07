using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace QuickBooksClone.Api.Middleware;

public sealed class ApiExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ApiExceptionHandlingMiddleware> _logger;

    public ApiExceptionHandlingMiddleware(RequestDelegate next, ILogger<ApiExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception exception) when (!context.Response.HasStarted)
        {
            var problem = CreateProblemDetails(context, exception);

            if (problem.Status >= StatusCodes.Status500InternalServerError)
            {
                _logger.LogError(exception, "Unhandled API exception for {Method} {Path}.", context.Request.Method, context.Request.Path);
            }
            else
            {
                _logger.LogWarning(exception, "Handled API exception for {Method} {Path}.", context.Request.Method, context.Request.Path);
            }

            context.Response.Clear();
            context.Response.StatusCode = problem.Status ?? StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "application/problem+json";
            await context.Response.WriteAsJsonAsync(problem, context.RequestAborted);
        }
    }

    private static ProblemDetails CreateProblemDetails(HttpContext context, Exception exception)
    {
        var (status, title, detail) = exception switch
        {
            ArgumentException => (
                StatusCodes.Status400BadRequest,
                "Invalid request.",
                exception.Message),
            InvalidOperationException => (
                StatusCodes.Status409Conflict,
                "The requested operation cannot be completed.",
                exception.Message),
            DbUpdateConcurrencyException => (
                StatusCodes.Status409Conflict,
                "The record was changed by another operation.",
                exception.Message),
            DbUpdateException => (
                StatusCodes.Status409Conflict,
                "The data change could not be saved.",
                exception.InnerException?.Message ?? exception.Message),
            _ => (
                StatusCodes.Status500InternalServerError,
                "An unexpected server error occurred.",
                "The server could not complete the request.")
        };

        var problem = new ProblemDetails
        {
            Status = status,
            Title = title,
            Detail = detail,
            Instance = context.Request.Path
        };

        problem.Extensions["traceId"] = context.TraceIdentifier;
        return problem;
    }
}
