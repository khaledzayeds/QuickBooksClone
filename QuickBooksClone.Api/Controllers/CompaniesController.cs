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
    private readonly ILogger<CompaniesController> _logger;

    public CompaniesController(ICompanyRuntimeService runtime, ILogger<CompaniesController> logger)
    {
        _runtime = runtime;
        _logger = logger;
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
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(TimeSpan.FromSeconds(45));
        var openCancellationToken = timeout.Token;

        try
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

            _logger.LogInformation("Open company {CompanyId}: before runtime open. DatabasePath={DatabasePath}", request.CompanyId, request.DatabasePath);
            var runtime = await _runtime.OpenAsync(
                request.CompanyId,
                request.CompanyName,
                request.DatabasePath,
                openCancellationToken);
            _logger.LogInformation("Open company {CompanyId}: runtime open completed.", request.CompanyId);

            _logger.LogInformation("Open company {CompanyId}: before ApplyCurrentCompanyDatabaseAsync.", request.CompanyId);
            await HttpContext.RequestServices.ApplyCurrentCompanyDatabaseAsync(seedDefaults: false, cancellationToken: openCancellationToken);
            _logger.LogInformation("Open company {CompanyId}: ApplyCurrentCompanyDatabaseAsync completed.", request.CompanyId);

            _logger.LogInformation("Open company {CompanyId}: before CurrentCompanyDatabaseIsInitializedAsync.", request.CompanyId);
            if (await HttpContext.RequestServices.CurrentCompanyDatabaseIsInitializedAsync(openCancellationToken))
            {
                _logger.LogInformation("Open company {CompanyId}: database is initialized, marking runtime initialized.", request.CompanyId);
                runtime = await _runtime.MarkSetupInitializedAsync(openCancellationToken);
            }
            _logger.LogInformation("Open company {CompanyId}: before returning OK.", request.CompanyId);

            return Ok(ToResponse(runtime));
        }
        catch (OperationCanceledException exception) when (!cancellationToken.IsCancellationRequested)
        {
            _logger.LogError(exception, "Open company timed out for {CompanyId}.", request.CompanyId);
            return Problem(
                title: "Company open timed out",
                detail: "The company database did not open within the expected time. Check the server log for the last completed open step.",
                statusCode: StatusCodes.Status504GatewayTimeout);
        }
        catch (Exception exception)
        {
            _logger.LogError(exception, "Open company failed for {CompanyId}.", request.CompanyId);
            return Problem(
                title: "Company open failed",
                detail: exception.Message,
                statusCode: StatusCodes.Status500InternalServerError);
        }
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
