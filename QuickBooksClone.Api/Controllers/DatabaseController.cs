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

    [HttpGet("backups")]
    [ProducesResponseType(typeof(DatabaseBackupListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<DatabaseBackupListResponse>> ListBackups(CancellationToken cancellationToken = default)
    {
        var backups = await _databaseMaintenance.ListBackupsAsync(cancellationToken);
        return Ok(new DatabaseBackupListResponse(
            backups.Select(ToDto).ToList(),
            backups.Count));
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
            var backup = await _databaseMaintenance.CreateBackupAsync(request?.Label, cancellationToken);
            return CreatedAtAction(
                nameof(ListBackups),
                new DatabaseBackupOperationResultDto(
                    backup.FileName,
                    backup.FullPath,
                    backup.SizeBytes,
                    backup.CreatedAt,
                    false));
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
        try
        {
            var result = await _databaseMaintenance.RestoreBackupAsync(request.FileName, request.CreateSafetyBackup, cancellationToken);
            return Ok(new DatabaseBackupOperationResultDto(
                result.RestoredBackup.FileName,
                result.RestoredBackup.FullPath,
                result.RestoredBackup.SizeBytes,
                result.RestoredBackup.CreatedAt,
                result.SafetyBackup is not null));
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
            backup.CreatedAt);
}
