using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Licensing;
using QuickBooksClone.Core.Licensing;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/licenses")]
public sealed class LicensesController : ControllerBase
{
    private readonly ILicenseActivationService _activationService;

    public LicensesController(ILicenseActivationService activationService)
    {
        _activationService = activationService;
    }

    [HttpPost("activate")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ActivateLicenseResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ActivateLicenseResponse>> Activate(ActivateLicenseRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _activationService.ActivateAsync(
                new LicenseActivationRequest(
                    request.Serial,
                    request.DeviceFingerprint,
                    request.AppVersion,
                    request.CompanyName),
                cancellationToken);

            return Ok(new ActivateLicenseResponse(
                result.LicensePackage,
                result.Serial,
                result.Edition,
                result.Status,
                result.IssuedAt,
                result.ExpiresAt));
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }
}
