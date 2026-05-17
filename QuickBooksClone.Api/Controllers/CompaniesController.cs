using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Companies;
using QuickBooksClone.Core.Companies;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/companies")]
public sealed class CompaniesController : ControllerBase
{
    private readonly ICompanyRuntimeService _runtime;

    public CompaniesController(ICompanyRuntimeService runtime)
    {
        _runtime = runtime;
    }

    [HttpGet("active")]
    [ProducesResponseType(typeof(ActiveCompanyRuntimeResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<ActiveCompanyRuntimeResponse>> GetActive(CancellationToken cancellationToken = default)
    {
        var runtime = await _runtime.GetActiveAsync(cancellationToken);
        return Ok(ToResponse(runtime));
    }

    [HttpPost("open")]
    [ProducesResponseType(typeof(ActiveCompanyRuntimeResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ActiveCompanyRuntimeResponse>> Open(OpenCompanyRequest request, CancellationToken cancellationToken = default)
    {
        if (request.CompanyId == Guid.Empty)
        {
            return BadRequest("Company id is required.");
        }

        if (string.IsNullOrWhiteSpace(request.CompanyName))
        {
            return BadRequest("Company name is required.");
        }

        if (string.IsNullOrWhiteSpace(request.DatabasePath))
        {
            return BadRequest("Database path is required.");
        }

        var runtime = await _runtime.OpenAsync(
            request.CompanyId,
            request.CompanyName,
            request.DatabasePath,
            cancellationToken);
        await HttpContext.RequestServices.ApplyCurrentCompanyDatabaseAsync(cancellationToken);
        if (await HttpContext.RequestServices.CurrentCompanyDatabaseIsInitializedAsync(cancellationToken))
        {
            runtime = await _runtime.MarkSetupInitializedAsync(cancellationToken);
        }

        return Ok(ToResponse(runtime));
    }

    [HttpPost("close")]
    [ProducesResponseType(typeof(ActiveCompanyRuntimeResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<ActiveCompanyRuntimeResponse>> Close(CancellationToken cancellationToken = default)
    {
        var runtime = await _runtime.CloseAsync(cancellationToken);
        return Ok(ToResponse(runtime));
    }

    private static ActiveCompanyRuntimeResponse ToResponse(ActiveCompanyRuntime runtime)
    {
        return new ActiveCompanyRuntimeResponse(
            runtime.CompanyId,
            runtime.CompanyName,
            runtime.DatabasePath,
            runtime.IsActive,
            runtime.OpenedAtUtc,
            runtime.IsSetupInitialized);
    }
}
