using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Database;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/database")]
public sealed class DatabaseController : ControllerBase
{
    private readonly IDatabaseMaintenanceService _databaseMaintenance;

    public DatabaseController(IDatabaseMaintenanceService databaseMaintenance)
    {
        _databaseMaintenance = databaseMaintenance;
    }

    [HttpGet("status")]
    [ProducesResponseType(typeof(DatabaseStatusDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<DatabaseStatusDto>> GetStatus(CancellationToken cancellationToken = default)
    {
        var status = await _databaseMaintenance.GetStatusAsync(cancellationToken);
        return Ok(new DatabaseStatusDto(
            status.Provider,
            status.SupportsBackupRestore,
            status.LiveDatabasePath,
            status.BackupDirectory,
            status.BackupCount));
    }

    [HttpGet("settings")]
    [ProducesResponseType(typeof(DatabaseMaintenanceSettingsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<DatabaseMaintenanceSettingsDto>> GetMaintenanceSettings(CancellationToken cancellationToken = default)
    {
        var settings = await _databaseMaintenance.GetMaintenanceSettingsAsync(cancellationToken);
        return Ok(ToDto(settings));
    }

    [HttpPut("settings")]
    [ProducesResponseType(typeof(DatabaseMaintenanceSettingsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<DatabaseMaintenanceSettingsDto>> UpdateMaintenanceSettings(
        UpdateDatabaseMaintenanceSettingsRequest request,
        CancellationToken cancellationToken = default)
    {
        var settings = await _databaseMaintenance.UpdateMaintenanceSettingsAsync(
            new DatabaseMaintenanceSettings(
                request.AutoBackupEnabled,
                request.ScheduleMode,
                request.RunAtHourLocal,
                request.RetentionCount,
                request.CreateSafetyBackupBeforeRestore,
                request.PreferredLabelPrefix,
                null,
                request.UpdatedBy),
            cancellationToken);

        return Ok(ToDto(settings));
    }

    [HttpGet("backups")]
    [ProducesResponseType(typeof(DatabaseBackupListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<DatabaseBackupListResponse>> ListBackups(CancellationToken cancellationToken = default)
    {
        var backups = await _databaseMaintenance.ListBackupsAsync(cancellationToken);
        return Ok(new DatabaseBackupListResponse(
            backups.Select(ToDto).ToList(),
            backups.Count));
    }

    [HttpGet("restore-audits")]
    [ProducesResponseType(typeof(DatabaseRestoreAuditListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<DatabaseRestoreAuditListResponse>> ListRestoreAudits(CancellationToken cancellationToken = default)
    {
        var audits = await _databaseMaintenance.ListRestoreAuditsAsync(cancellationToken);
        return Ok(new DatabaseRestoreAuditListResponse(
            audits.Select(ToDto).ToList(),
            audits.Count));
    }

    [HttpPost("backups")]
    [ProducesResponseType(typeof(DatabaseBackupOperationResultDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<DatabaseBackupOperationResultDto>> CreateBackup(
        CreateDatabaseBackupRequest? request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var backup = await _databaseMaintenance.CreateBackupAsync(request?.Label, request?.RequestedBy, request?.Reason, cancellationToken);
            return StatusCode(
                StatusCodes.Status201Created,
                new DatabaseBackupOperationResultDto(
                    backup.FileName,
                    backup.FullPath,
                    backup.SizeBytes,
                    backup.CreatedAt,
                    false,
                    backup.BackupKind,
                    backup.Label,
                    backup.RequestedBy,
                    backup.Reason,
                    null,
                    null));
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPost("backups/import")]
    [ProducesResponseType(typeof(DatabaseBackupOperationResultDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [RequestSizeLimit(250_000_000)]
    public async Task<ActionResult<DatabaseBackupOperationResultDto>> ImportBackup(
        [FromForm] ImportDatabaseBackupRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.File is null || request.File.Length == 0)
        {
            return BadRequest("A backup file is required.");
        }

        try
        {
            await using var stream = request.File.OpenReadStream();
            var importedBackup = await _databaseMaintenance.ImportBackupAsync(
                request.File.FileName,
                stream,
                request.Label,
                request.RequestedBy,
                request.Reason,
                cancellationToken);

            return StatusCode(
                StatusCodes.Status201Created,
                new DatabaseBackupOperationResultDto(
                    importedBackup.FileName,
                    importedBackup.FullPath,
                    importedBackup.SizeBytes,
                    importedBackup.CreatedAt,
                    false,
                    importedBackup.BackupKind,
                    importedBackup.Label,
                    importedBackup.RequestedBy,
                    importedBackup.Reason,
                    null,
                    null));
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPost("backups/restore")]
    [ProducesResponseType(typeof(DatabaseBackupOperationResultDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<DatabaseBackupOperationResultDto>> RestoreBackup(
        RestoreDatabaseBackupRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!request.ConfirmRestore)
        {
            return BadRequest("Restore requires explicit confirmation. Set confirmRestore=true to continue.");
        }

        try
        {
            var result = await _databaseMaintenance.RestoreBackupAsync(
                request.FileName,
                request.CreateSafetyBackup,
                request.RequestedBy,
                request.Reason,
                cancellationToken);

            return Ok(new DatabaseBackupOperationResultDto(
                result.RestoredBackup.FileName,
                result.RestoredBackup.FullPath,
                result.RestoredBackup.SizeBytes,
                result.RestoredBackup.CreatedAt,
                result.SafetyBackup is not null,
                result.RestoredBackup.BackupKind,
                result.RestoredBackup.Label,
                result.RestoredBackup.RequestedBy,
                result.RestoredBackup.Reason,
                result.SafetyBackup?.FileName,
                result.RestoreAudit.RestoredAt));
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
        catch (FileNotFoundException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    private static DatabaseBackupDto ToDto(DatabaseBackupFile backup) =>
        new(
            backup.FileName,
            backup.FullPath,
            backup.SizeBytes,
            backup.CreatedAt,
            backup.BackupKind,
            backup.Label,
            backup.RequestedBy,
            backup.Reason);

    private static DatabaseMaintenanceSettingsDto ToDto(DatabaseMaintenanceSettings settings) =>
        new(
            settings.AutoBackupEnabled,
            settings.ScheduleMode,
            settings.RunAtHourLocal,
            settings.RetentionCount,
            settings.CreateSafetyBackupBeforeRestore,
            settings.PreferredLabelPrefix,
            settings.UpdatedAt,
            settings.UpdatedBy);

    private static DatabaseRestoreAuditDto ToDto(DatabaseRestoreAudit audit) =>
        new(
            audit.BackupFileName,
            audit.BackupFullPath,
            audit.RestoredAt,
            audit.CreatedSafetyBackup,
            audit.SafetyBackupFileName,
            audit.RequestedBy,
            audit.Reason,
            audit.LiveDatabasePath,
            audit.Provider);
}
