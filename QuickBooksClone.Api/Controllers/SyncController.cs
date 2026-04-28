using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Sync;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.Sync;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/sync")]
[RequirePermission("Data.Sync.Manage")]
public sealed class SyncController : ControllerBase
{
    private readonly ISyncDiagnosticsService _diagnostics;

    public SyncController(ISyncDiagnosticsService diagnostics)
    {
        _diagnostics = diagnostics;
    }

    [HttpGet("overview")]
    [ProducesResponseType(typeof(SyncOverviewDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<SyncOverviewDto>> GetOverview(CancellationToken cancellationToken = default)
    {
        var overview = await _diagnostics.GetOverviewAsync(cancellationToken);
        return Ok(new SyncOverviewDto(
            overview.GeneratedAt,
            overview.DocumentTypes
                .Select(current => new SyncDocumentTypeSummaryDto(
                    current.DocumentType,
                    current.TotalDocuments,
                    current.LocalOnlyCount,
                    current.PendingSyncCount,
                    current.SyncedCount,
                    current.SyncFailedCount,
                    current.LastModifiedAt))
                .ToList(),
            overview.TotalDocuments,
            overview.LocalOnlyCount,
            overview.PendingSyncCount,
            overview.SyncedCount,
            overview.SyncFailedCount));
    }

    [HttpGet("documents")]
    [ProducesResponseType(typeof(IReadOnlyList<SyncDocumentDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<IReadOnlyList<SyncDocumentDto>>> GetDocuments(
        [FromQuery] SyncStatus? status = null,
        [FromQuery] string? documentType = null,
        [FromQuery] int take = 200,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var documents = await _diagnostics.ListDocumentsAsync(status, documentType, take, cancellationToken);
            return Ok(documents
                .Select(current => new SyncDocumentDto(
                    current.DocumentType,
                    current.Id,
                    current.DocumentNo,
                    current.DeviceId,
                    current.SyncStatus,
                    current.SyncVersion,
                    current.CreatedAt,
                    current.LastModifiedAt,
                    current.LastSyncAt,
                    current.SyncError))
                .ToList());
        }
        catch (ArgumentOutOfRangeException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPost("documents/{documentType}/{id:guid}/mark-pending")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult> MarkPending(string documentType, Guid id, CancellationToken cancellationToken = default)
    {
        try
        {
            var updated = await _diagnostics.MarkPendingAsync(documentType, id, cancellationToken);
            return updated ? NoContent() : NotFound();
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }
}
