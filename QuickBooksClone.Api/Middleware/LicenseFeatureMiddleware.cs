using Microsoft.AspNetCore.Authorization;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Licensing;

namespace QuickBooksClone.Api.Middleware;

public sealed class LicenseFeatureMiddleware
{
    private readonly RequestDelegate _next;

    public LicenseFeatureMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, ILicenseFeatureAccessService licenseAccessService)
    {
        var endpoint = context.GetEndpoint();
        if (endpoint is null || endpoint.Metadata.GetMetadata<IAllowAnonymous>() is not null)
        {
            await _next(context);
            return;
        }

        var requiredFeatures = endpoint.Metadata
            .GetOrderedMetadata<RequireLicenseFeatureAttribute>()
            .Select(metadata => metadata.Feature)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (requiredFeatures.Count == 0)
        {
            await _next(context);
            return;
        }

        foreach (var feature in requiredFeatures)
        {
            var result = licenseAccessService.CheckFeature(feature);
            if (!result.Allowed)
            {
                context.Response.StatusCode = StatusCodes.Status402PaymentRequired;
                await context.Response.WriteAsync(result.Message);
                return;
            }
        }

        await _next(context);
    }
}
