using Microsoft.AspNetCore.Mvc;
using Zayed.Api.Contracts.Modules;
using Zayed.Core.Modules;

namespace Zayed.Api.Controllers;

[ApiController]
[Route("api/company-modules")]
public sealed class CompanyModulesController : ControllerBase
{
    private readonly ICompanyModuleAccessService _modules;

    public CompanyModulesController(ICompanyModuleAccessService modules)
    {
        _modules = modules;
    }

    [HttpGet("current")]
    [ProducesResponseType(typeof(CurrentCompanyModulesResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<CurrentCompanyModulesResponse>> GetCurrent(CancellationToken cancellationToken = default)
    {
        var result = await _modules.GetCurrentModulesAsync(cancellationToken);
        return Ok(new CurrentCompanyModulesResponse(result.BusinessType, result.EnabledModules));
    }
}
