using Microsoft.AspNetCore.Mvc;
using Zayed.Core.Companies;

namespace Zayed.Api.Middleware;

public sealed class ActiveCompanyRequiredMiddleware
{
    private static readonly PathString ApiRootPath = new("/api");
    private static readonly PathString HealthPath = new("/api/health");
    private static readonly PathString AuthPath = new("/api/auth");
    private static readonly PathString CompaniesRuntimePath = new("/api/companies");
    private static readonly PathString LicensesPath = new("/api/licenses");
    private static readonly PathString SetupPath = new("/api/setup");
    private static readonly PathString RuntimeSettingsPath = new("/api/settings/runtime");

    private readonly RequestDelegate _next;

    public ActiveCompanyRequiredMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, ICompanyRuntimeService companyRuntime)
    {
        if (!context.Request.Path.StartsWithSegments(ApiRootPath, StringComparison.OrdinalIgnoreCase) ||
            context.Request.Path.StartsWithSegments(HealthPath, StringComparison.OrdinalIgnoreCase) ||
            context.Request.Path.StartsWithSegments(AuthPath, StringComparison.OrdinalIgnoreCase) ||
            context.Request.Path.StartsWithSegments(CompaniesRuntimePath, StringComparison.OrdinalIgnoreCase) ||
            context.Request.Path.StartsWithSegments(LicensesPath, StringComparison.OrdinalIgnoreCase) ||
            context.Request.Path.StartsWithSegments(SetupPath, StringComparison.OrdinalIgnoreCase) ||
            context.Request.Path.StartsWithSegments(RuntimeSettingsPath, StringComparison.OrdinalIgnoreCase))
        {
            await _next(context);
            return;
        }

        if (companyRuntime.Current.IsActive)
        {
            await _next(context);
            return;
        }

        context.Response.StatusCode = StatusCodes.Status409Conflict;
        await context.Response.WriteAsJsonAsync(new ProblemDetails
        {
            Title = "No active company",
            Detail = "Open a company file before requesting company data.",
            Status = StatusCodes.Status409Conflict,
        });
    }
}
