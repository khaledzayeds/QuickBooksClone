using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Backups;
using QuickBooksClone.Api.Middleware;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/backups")]
[RequireLicenseFeature(LicenseFeatureNames.BackupRestore)]
public sealed class BackupsController : ControllerBase
{
    private readonly IDatabaseMaintenanceService _databaseMaintenance;

    public BackupsController(IDatabaseMaintenanceService databaseMaintenance)
    {
        _databaseMaintenance = databaseMaintenance;
    }

    [HttpGet]
    [RequireAuthenticated]
    [ProducesResponseType(typeof(IReadOnlyList<BackupFileDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<BackupFileDto>>> ListBackups(CancellationToken cancellationToken = default)
    {
        var backups = await _databaseMaintenance.ListBackupsAsync(cancellationToken);
        return Ok(backups.Select(ToDto).ToList());
    }

    [HttpGet("settings")]
    [RequireAuthenticated]
    [ProducesResponseType(typeof(DatabaseMaintenanceSettingsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<DatabaseMaintenanceSettingsDto>> GetSettings(CancellationToken cancellationToken = default)
    {
        var settings = await _databaseMaintenance.GetMaintenanceSettingsAsync(cancellationToken);
        return Ok(ToDto(settings));
    }

    [HttpPut("settings")]
    [RequirePermission("Settings.Manage")]
    [ProducesResponseType(typeof(DatabaseMaintenanceSettingsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<DatabaseMaintenanceSettingsDto>> UpdateSettings(UpdateDatabaseMaintenanceSettingsRequest request, CancellationToken cancellationToken = default)
    {
        var settings = await _databaseMaintenance.UpdateMaintenanceSettingsAsync(
            new DatabaseMaintenanceSettings(
                request.AutoBackupEnabled,
                request.ScheduleMode,
                request.RunAtHourLocal,
                request.RetentionCount,
                request.CreateSafetyBackupBeforeRestore,
                request.PreferredLabelPrefix,
                UpdatedAt: null,
                UpdatedBy: GetUserName()),
            cancellationToken);

        return Ok(ToDto(settings));
    }

    [HttpPost]
    [RequirePermission("Settings.Manage")]
    [ProducesResponseType(typeof(BackupFileDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<BackupFileDto>> CreateBackup(CreateBackupRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var backup = await _databaseMaintenance.CreateBackupAsync(request.Label, GetUserName(), request.Reason, cancellationToken);
            return Ok(ToDto(backup));
        }
        catch (Exception exception) when (exception is InvalidOperationException or IOException)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPost("import")]
    [RequirePermission("Settings.Manage")]
    [RequestSizeLimit(500_000_000)]
    [ProducesResponseType(typeof(BackupFileDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<BackupFileDto>> ImportBackup([FromForm] IFormFile file, [FromForm] string? label, [FromForm] string? reason, CancellationToken cancellationToken = default)
    {
        if (file.Length == 0)
        {
            return BadRequest("Backup file is empty.");
        }

        try
        {
            await using var stream = file.OpenReadStream();
            var backup = await _databaseMaintenance.ImportBackupAsync(file.FileName, stream, label, GetUserName(), reason, cancellationToken);
            return Ok(ToDto(backup));
        }
        catch (Exception exception) when (exception is InvalidOperationException or IOException)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPost("restore")]
    [RequirePermission("Settings.Manage")]
    [ProducesResponseType(typeof(RestoreBackupResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<RestoreBackupResponse>> RestoreBackup(RestoreBackupRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _databaseMaintenance.RestoreBackupAsync(
                request.FileName,
                request.CreateSafetyBackup,
                GetUserName(),
                request.Reason,
                cancellationToken);

            return Ok(new RestoreBackupResponse(
                ToDto(result.RestoredBackup),
                result.SafetyBackup is null ? null : ToDto(result.SafetyBackup),
                ToDto(result.RestoreAudit)));
        }
        catch (Exception exception) when (exception is InvalidOperationException or IOException or FileNotFoundException)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpGet("restore-audits")]
    [RequireAuthenticated]
    [ProducesResponseType(typeof(IReadOnlyList<RestoreAuditDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<RestoreAuditDto>>> ListRestoreAudits(CancellationToken cancellationToken = default)
    {
        var audits = await _databaseMaintenance.ListRestoreAuditsAsync(cancellationToken);
        return Ok(audits.Select(ToDto).ToList());
    }

    private string? GetUserName()
    {
        return HttpContext.Items.TryGetValue(PermissionAuthorizationMiddleware.CurrentUserItemKey, out var value) && value is CurrentUserContext currentUser
            ? currentUser.UserName
            : null;
    }

    private static BackupFileDto ToDto(DatabaseBackupFile backup) => new(
        backup.FileName,
        backup.SizeBytes,
        backup.CreatedAt,
        backup.BackupKind,
        backup.Label,
        backup.RequestedBy,
        backup.Reason);

    private static DatabaseMaintenanceSettingsDto ToDto(DatabaseMaintenanceSettings settings) => new(
        settings.AutoBackupEnabled,
        settings.ScheduleMode,
        settings.RunAtHourLocal,
        settings.RetentionCount,
        settings.CreateSafetyBackupBeforeRestore,
        settings.PreferredLabelPrefix,
        settings.UpdatedAt,
        settings.UpdatedBy);

    private static RestoreAuditDto ToDto(DatabaseRestoreAudit audit) => new(
        audit.BackupFileName,
        audit.RestoredAt,
        audit.CreatedSafetyBackup,
        audit.SafetyBackupFileName,
        audit.RequestedBy,
        audit.Reason,
        audit.Provider);
}
