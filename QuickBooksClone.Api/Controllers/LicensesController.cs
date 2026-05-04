using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Licensing;
using QuickBooksClone.Core.Licensing;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/licenses")]
public sealed class LicensesController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly ILicenseActivationService _activationService;

    public LicensesController(IConfiguration configuration, ILicenseActivationService activationService)
    {
        _configuration = configuration;
        _activationService = activationService;
    }

    [HttpGet("status")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(LicenseStatusResponse), StatusCodes.Status200OK)]
    public ActionResult<LicenseStatusResponse> GetStatus()
    {
        var section = _configuration.GetSection("Licensing:CurrentLicense");
        var features = section.GetSection("Features").GetChildren()
            .ToDictionary(child => child.Key, child => bool.TryParse(child.Value, out var value) && value, StringComparer.OrdinalIgnoreCase);
        var expiresAtRaw = section.GetValue<string>("ExpiresAt");
        var expiresAt = DateTimeOffset.TryParse(expiresAtRaw, out var parsed) ? parsed : (DateTimeOffset?)null;

        return Ok(new LicenseStatusResponse(
            section.GetValue("Edition", "unknown")!,
            section.GetValue("Status", "inactive")!,
            expiresAt,
            features));
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
