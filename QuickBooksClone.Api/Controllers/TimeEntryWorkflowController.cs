using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Contracts.TimeTracking;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.TimeTracking;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/time-entries/{id:guid}")]
[RequirePermission("TimeTracking.Manage")]
public sealed class TimeEntryWorkflowController : ControllerBase
{
    private readonly QuickBooksCloneDbContext _db;

    public TimeEntryWorkflowController(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    [HttpPost("mark-billable")]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TimeEntryDto>> MarkBillable(Guid id, CancellationToken cancellationToken = default)
    {
        await EnsureInvoiceColumnAsync(cancellationToken);
        var row = await GetRowAsync(id, cancellationToken);
        if (row is null) return NotFound();

        if (row.Status != TimeEntryStatus.Approved)
        {
            return BadRequest("Only approved time entries can be marked billable.");
        }
        if (!row.IsBillable)
        {
            return BadRequest("Only billable time entries can move to billable status.");
        }
        if (row.CustomerId is null || row.ServiceItemId is null)
        {
            return BadRequest("Billable time entries require customer and service item before invoicing.");
        }

        await ExecuteNonQueryAsync(
            "UPDATE time_entries SET Status = @Status, UpdatedAt = @UpdatedAt WHERE Id = @Id",
            new Dictionary<string, object?>
            {
                ["Id"] = id,
                ["Status"] = (int)TimeEntryStatus.Billable,
                ["UpdatedAt"] = DateTimeOffset.UtcNow,
            },
            cancellationToken);

        return Ok(await BuildDtoAsync(id, cancellationToken));
    }

    [HttpPost("mark-invoiced-with-link")]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TimeEntryDto>> MarkInvoiced(Guid id, MarkTimeEntryInvoicedRequest request, CancellationToken cancellationToken = default)
    {
        await EnsureInvoiceColumnAsync(cancellationToken);
        var row = await GetRowAsync(id, cancellationToken);
        if (row is null) return NotFound();

        if (row.Status is not TimeEntryStatus.Approved and not TimeEntryStatus.Billable)
        {
            return BadRequest("Only approved or billable time entries can be marked invoiced.");
        }
        if (row.IsBillable && (row.CustomerId is null || row.ServiceItemId is null))
        {
            return BadRequest("Billable time entries require customer and service item before invoicing.");
        }
        if (request.InvoiceId is not null && !await _db.Invoices.AnyAsync(invoice => invoice.Id == request.InvoiceId.Value, cancellationToken))
        {
            return BadRequest("Invoice does not exist.");
        }

        await ExecuteNonQueryAsync(
            "UPDATE time_entries SET Status = @Status, InvoiceId = @InvoiceId, UpdatedAt = @UpdatedAt WHERE Id = @Id",
            new Dictionary<string, object?>
            {
                ["Id"] = id,
                ["Status"] = (int)TimeEntryStatus.Invoiced,
                ["InvoiceId"] = request.InvoiceId,
                ["UpdatedAt"] = DateTimeOffset.UtcNow,
            },
            cancellationToken);

        return Ok(await BuildDtoAsync(id, cancellationToken));
    }

    private async Task EnsureInvoiceColumnAsync(CancellationToken cancellationToken)
    {
        await ExecuteNonQueryAsync(
            """
            IF OBJECT_ID(N'time_entries', N'U') IS NOT NULL AND COL_LENGTH('time_entries', 'InvoiceId') IS NULL
            BEGIN
                ALTER TABLE time_entries ADD InvoiceId uniqueidentifier NULL;
                CREATE INDEX IX_time_entries_InvoiceId ON time_entries (InvoiceId);
            END
            """,
            new Dictionary<string, object?>(),
            cancellationToken);
    }

    private async Task<TimeEntryWorkflowRow?> GetRowAsync(Guid id, CancellationToken cancellationToken)
    {
        var rows = await QueryAsync(
            """
            SELECT Id, WorkDate, PersonName, Hours, Activity, Notes, CustomerId, ServiceItemId, InvoiceId, IsBillable, Status, CreatedAt, UpdatedAt
            FROM time_entries
            WHERE Id = @Id
            """,
            new Dictionary<string, object?> { ["Id"] = id },
            reader => new TimeEntryWorkflowRow(
                reader.GetGuid(0),
                DateOnly.FromDateTime(reader.GetDateTime(1)),
                reader.GetString(2),
                reader.GetDecimal(3),
                reader.GetString(4),
                reader.IsDBNull(5) ? null : reader.GetString(5),
                reader.IsDBNull(6) ? null : reader.GetGuid(6),
                reader.IsDBNull(7) ? null : reader.GetGuid(7),
                reader.IsDBNull(8) ? null : reader.GetGuid(8),
                reader.GetBoolean(9),
                (TimeEntryStatus)reader.GetInt32(10),
                reader.GetFieldValue<DateTimeOffset>(11),
                reader.IsDBNull(12) ? null : reader.GetFieldValue<DateTimeOffset>(12)),
            cancellationToken);

        return rows.SingleOrDefault();
    }

    private async Task<TimeEntryDto> BuildDtoAsync(Guid id, CancellationToken cancellationToken)
    {
        var row = await GetRowAsync(id, cancellationToken) ?? throw new InvalidOperationException("Time entry was not found after update.");
        var customerName = row.CustomerId is null
            ? null
            : await _db.Customers.AsNoTracking().Where(customer => customer.Id == row.CustomerId.Value).Select(customer => customer.DisplayName).SingleOrDefaultAsync(cancellationToken);
        var itemName = row.ServiceItemId is null
            ? null
            : await _db.Items.AsNoTracking().Where(item => item.Id == row.ServiceItemId.Value).Select(item => item.Name).SingleOrDefaultAsync(cancellationToken);

        return new TimeEntryDto(
            row.Id,
            row.WorkDate,
            row.PersonName,
            row.Hours,
            row.Activity,
            row.Notes,
            row.CustomerId,
            customerName,
            row.ServiceItemId,
            itemName,
            row.InvoiceId,
            row.IsBillable,
            row.Status,
            row.CreatedAt,
            row.UpdatedAt);
    }

    private async Task ExecuteNonQueryAsync(string sql, IReadOnlyDictionary<string, object?> parameters, CancellationToken cancellationToken)
    {
        await using var command = _db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        AddParameters(command, parameters);
        if (command.Connection!.State != ConnectionState.Open) await command.Connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private async Task<IReadOnlyList<T>> QueryAsync<T>(string sql, IReadOnlyDictionary<string, object?> parameters, Func<System.Data.Common.DbDataReader, T> mapper, CancellationToken cancellationToken)
    {
        var result = new List<T>();
        await using var command = _db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        AddParameters(command, parameters);
        if (command.Connection!.State != ConnectionState.Open) await command.Connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) result.Add(mapper(reader));
        return result;
    }

    private static void AddParameters(IDbCommand command, IReadOnlyDictionary<string, object?> parameters)
    {
        foreach (var (name, value) in parameters)
        {
            var parameter = command.CreateParameter();
            parameter.ParameterName = $"@{name}";
            parameter.Value = value ?? DBNull.Value;
            command.Parameters.Add(parameter);
        }
    }

    private sealed record TimeEntryWorkflowRow(
        Guid Id,
        DateOnly WorkDate,
        string PersonName,
        decimal Hours,
        string Activity,
        string? Notes,
        Guid? CustomerId,
        Guid? ServiceItemId,
        Guid? InvoiceId,
        bool IsBillable,
        TimeEntryStatus Status,
        DateTimeOffset CreatedAt,
        DateTimeOffset? UpdatedAt);
}
