using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Security;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Security;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/audit")]
[RequirePermission("Audit.View")]
public sealed class AuditController : ControllerBase
{
    private readonly IAuditLogRepository _auditLog;

    public AuditController(IAuditLogRepository auditLog)
    {
        _auditLog = auditLog;
    }

    [HttpGet]
    [ProducesResponseType(typeof(AuditLogListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<AuditLogListResponse>> Search(
        [FromQuery] Guid? userId,
        [FromQuery] string? userName,
        [FromQuery] string? action,
        [FromQuery] string? controller,
        [FromQuery] DateTimeOffset? from,
        [FromQuery] DateTimeOffset? to,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        var result = await _auditLog.SearchAsync(
            new AuditLogSearch(userId, userName, action, controller, from, to, page, pageSize),
            cancellationToken);

        return Ok(new AuditLogListResponse(
            result.Items.Select(ToDto).ToList(),
            result.TotalCount,
            result.Page,
            result.PageSize));
    }

    private static AuditLogEntryDto ToDto(AuditLogEntry entry) => new(
        entry.Id,
        entry.UserId,
        entry.UserName,
        entry.Action,
        entry.HttpMethod,
        entry.Path,
        entry.StatusCode,
        entry.Controller,
        entry.EndpointAction,
        entry.RequiredPermissions,
        entry.IpAddress,
        entry.UserAgent,
        entry.OccurredAt);
}
