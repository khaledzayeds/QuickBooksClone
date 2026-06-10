using Microsoft.AspNetCore.Mvc;
using Zayed.Api.Contracts.Modules;
using Zayed.Core.Modules;
using Zayed.Infrastructure.Modules;

namespace Zayed.Api.Controllers;

[ApiController]
[Route("api/hotels")]
public sealed class HotelsController : ControllerBase
{
    private readonly ICompanyModuleAccessService _modules;

    public HotelsController(ICompanyModuleAccessService modules)
    {
        _modules = modules;
    }

    [HttpGet("status")]
    [ProducesResponseType(typeof(HotelModuleStatusResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<HotelModuleStatusResponse>> GetStatus(CancellationToken cancellationToken = default)
    {
        return await RequireHotelModuleAsync(ModuleCodes.Hotels, cancellationToken);
    }

    [HttpGet("menu-check/{moduleCode}")]
    [ProducesResponseType(typeof(HotelModuleStatusResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<HotelModuleStatusResponse>> CheckMenu(string moduleCode, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(moduleCode) || !moduleCode.StartsWith("hotel", StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest("Hotel module code is required.");
        }

        return await RequireHotelModuleAsync(moduleCode, cancellationToken);
    }

    private async Task<ActionResult<HotelModuleStatusResponse>> RequireHotelModuleAsync(string moduleCode, CancellationToken cancellationToken)
    {
        try
        {
            await _modules.RequireModuleAsync(moduleCode, cancellationToken);
            return Ok(new HotelModuleStatusResponse(moduleCode, Enabled: true, "Module is enabled for this company."));
        }
        catch (ModuleNotEnabledException exception)
        {
            return StatusCode(
                StatusCodes.Status403Forbidden,
                new HotelModuleStatusResponse(moduleCode, Enabled: false, exception.Message));
        }
    }
}
