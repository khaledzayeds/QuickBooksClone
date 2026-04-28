using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using QuickBooksClone.Api.Contracts.Settings;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/settings")]
public sealed class SettingsController : ControllerBase
{
    private readonly ICompanySettingsRepository _companySettings;
    private readonly IDeviceSettingsRepository _deviceSettings;
    private readonly IDatabaseMaintenanceService _databaseMaintenance;
    private readonly IWebHostEnvironment _environment;

    public SettingsController(
        ICompanySettingsRepository companySettings,
        IDeviceSettingsRepository deviceSettings,
        IDatabaseMaintenanceService databaseMaintenance,
        IWebHostEnvironment environment)
    {
        _companySettings = companySettings;
        _deviceSettings = deviceSettings;
        _databaseMaintenance = databaseMaintenance;
        _environment = environment;
    }

    [HttpGet("company")]
    [RequireAuthenticated]
    [ProducesResponseType(typeof(CompanySettingsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CompanySettingsDto>> GetCompany(CancellationToken cancellationToken = default)
    {
        var settings = await _companySettings.GetAsync(cancellationToken);
        return settings is null ? NotFound() : Ok(ToDto(settings));
    }

    [HttpPut("company")]
    [RequirePermission("Settings.Manage")]
    [ProducesResponseType(typeof(CompanySettingsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CompanySettingsDto>> UpdateCompany(UpdateCompanySettingsRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var settings = await _companySettings.UpdateAsync(
                request.CompanyName,
                request.Currency,
                request.Country,
                request.TimeZoneId,
                request.DefaultLanguage,
                request.LegalName,
                request.Email,
                request.Phone,
                request.TaxRegistrationNumber,
                request.AddressLine1,
                request.AddressLine2,
                request.City,
                request.Region,
                request.PostalCode,
                request.FiscalYearStartMonth,
                request.FiscalYearStartDay,
                request.DefaultSalesTaxRate,
                request.DefaultPurchaseTaxRate,
                cancellationToken);

            return Ok(ToDto(settings));
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpGet("device")]
    [RequireAuthenticated]
    [ProducesResponseType(typeof(DeviceSettingsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<DeviceSettingsDto>> GetDevice(CancellationToken cancellationToken = default)
    {
        var settings = await _deviceSettings.GetOrCreateAsync(cancellationToken);
        return Ok(ToDto(settings));
    }

    [HttpPut("device")]
    [RequirePermission("Settings.Manage")]
    [ProducesResponseType(typeof(DeviceSettingsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<DeviceSettingsDto>> UpdateDevice(UpdateDeviceSettingsRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var settings = await _deviceSettings.UpsertAsync(request.DeviceId, request.DeviceName, cancellationToken);
            return Ok(ToDto(settings));
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpGet("runtime")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(RuntimeSettingsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<RuntimeSettingsDto>> GetRuntime(CancellationToken cancellationToken = default)
    {
        var databaseStatus = await _databaseMaintenance.GetStatusAsync(cancellationToken);
        return Ok(new RuntimeSettingsDto(
            _environment.EnvironmentName,
            databaseStatus.Provider,
            databaseStatus.SupportsBackupRestore,
            databaseStatus.LiveDatabasePath,
            databaseStatus.BackupDirectory));
    }

    private static CompanySettingsDto ToDto(CompanySettings settings) =>
        new(
            settings.Id,
            settings.CompanyId,
            settings.CompanyName,
            settings.LegalName,
            settings.Email,
            settings.Phone,
            settings.Currency,
            settings.Country,
            settings.TimeZoneId,
            settings.DefaultLanguage,
            settings.TaxRegistrationNumber,
            settings.AddressLine1,
            settings.AddressLine2,
            settings.City,
            settings.Region,
            settings.PostalCode,
            settings.FiscalYearStartMonth,
            settings.FiscalYearStartDay,
            settings.DefaultSalesTaxRate,
            settings.DefaultPurchaseTaxRate);

    private static DeviceSettingsDto ToDto(DeviceSettings settings) =>
        new(settings.Id, settings.DeviceId, settings.DeviceName);
}
