using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Contracts.TimeTracking;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.TimeTracking;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/time-entries")]
[RequirePermission("TimeTracking.Manage")]
public sealed class TimeEntriesController : ControllerBase
{
    private const string CompanyId = "11111111-1111-1111-1111-111111111111";
    private readonly QuickBooksCloneDbContext _db;

    public TimeEntriesController(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    [ProducesResponseType(typeof(TimeEntryListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<TimeEntryListResponse>> Search(
        [FromQuery] DateOnly? fromDate,
        [FromQuery] DateOnly? toDate,
        [FromQuery] string? search,
        [FromQuery] TimeEntryStatus? status,
        [FromQuery] bool? isBillable,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        await EnsureTableAsync(cancellationToken);
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 200);

        var where = new List<string>();
        var parameters = new Dictionary<string, object?>();
        AddFilters(where, parameters, fromDate, toDate, search, status, isBillable);
        var whereSql = where.Count == 0 ? string.Empty : "WHERE " + string.Join(" AND ", where);

        var totalCount = Convert.ToInt32(await ExecuteScalarAsync($"SELECT COUNT(1) FROM time_entries {whereSql}", parameters, cancellationToken) ?? 0);
        var totalHours = Convert.ToDecimal(await ExecuteScalarAsync($"SELECT COALESCE(SUM(Hours), 0) FROM time_entries {whereSql}", parameters, cancellationToken) ?? 0);
        var billableParameters = new Dictionary<string, object?>(parameters);
        var billableWhere = new List<string>(where) { "IsBillable = 1" };
        var billableHours = Convert.ToDecimal(await ExecuteScalarAsync($"SELECT COALESCE(SUM(Hours), 0) FROM time_entries WHERE {string.Join(" AND ", billableWhere)}", billableParameters, cancellationToken) ?? 0);

        var rows = await QueryTimeEntriesAsync(
            $"""
            SELECT Id, CompanyId, WorkDate, PersonName, Hours, Activity, Notes, CustomerId, ServiceItemId, IsBillable, Status, CreatedAt, UpdatedAt
            FROM time_entries
            {whereSql}
            ORDER BY WorkDate DESC, PersonName ASC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY
            """,
            new Dictionary<string, object?>(parameters)
            {
                ["Offset"] = (page - 1) * pageSize,
                ["PageSize"] = pageSize
            },
            cancellationToken);

        return Ok(new TimeEntryListResponse(
            await ToDtosAsync(rows, cancellationToken),
            totalCount,
            page,
            pageSize,
            totalHours,
            billableHours,
            totalHours - billableHours));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TimeEntryDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        await EnsureTableAsync(cancellationToken);
        var rows = await QueryTimeEntriesAsync(
            "SELECT Id, CompanyId, WorkDate, PersonName, Hours, Activity, Notes, CustomerId, ServiceItemId, IsBillable, Status, CreatedAt, UpdatedAt FROM time_entries WHERE Id = @Id",
            new Dictionary<string, object?> { ["Id"] = id },
            cancellationToken);

        return rows.Count == 0 ? NotFound() : Ok((await ToDtosAsync(rows, cancellationToken)).Single());
    }

    [HttpPost]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<TimeEntryDto>> Create(CreateTimeEntryRequest request, CancellationToken cancellationToken = default)
    {
        await EnsureTableAsync(cancellationToken);
        var validation = await ValidateReferencesAsync(request.CustomerId, request.ServiceItemId, cancellationToken);
        if (validation is not null) return BadRequest(validation);

        try
        {
            var entry = new TimeEntry(request.WorkDate, request.PersonName, request.Hours, request.Activity, request.Notes, request.CustomerId, request.ServiceItemId, request.IsBillable);
            await ExecuteNonQueryAsync(
                """
                INSERT INTO time_entries (Id, CompanyId, WorkDate, PersonName, Hours, Activity, Notes, CustomerId, ServiceItemId, InvoiceId, IsBillable, Status, CreatedAt, UpdatedAt)
                VALUES (@Id, @CompanyId, @WorkDate, @PersonName, @Hours, @Activity, @Notes, @CustomerId, @ServiceItemId, NULL, @IsBillable, @Status, @CreatedAt, @UpdatedAt)
                """,
                ToParameters(entry),
                cancellationToken);

            var dto = (await ToDtosAsync([entry], cancellationToken)).Single();
            return CreatedAtAction(nameof(Get), new { id = entry.Id }, dto);
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TimeEntryDto>> Update(Guid id, UpdateTimeEntryRequest request, CancellationToken cancellationToken = default)
    {
        await EnsureTableAsync(cancellationToken);
        var rows = await QueryTimeEntriesAsync(
            "SELECT Id, CompanyId, WorkDate, PersonName, Hours, Activity, Notes, CustomerId, ServiceItemId, IsBillable, Status, CreatedAt, UpdatedAt FROM time_entries WHERE Id = @Id",
            new Dictionary<string, object?> { ["Id"] = id },
            cancellationToken);
        if (rows.Count == 0) return NotFound();

        var validation = await ValidateReferencesAsync(request.CustomerId, request.ServiceItemId, cancellationToken);
        if (validation is not null) return BadRequest(validation);

        try
        {
            var entry = rows.Single();
            entry.Update(request.WorkDate, request.PersonName, request.Hours, request.Activity, request.Notes, request.CustomerId, request.ServiceItemId, request.IsBillable);
            await ExecuteNonQueryAsync(
                """
                UPDATE time_entries
                SET WorkDate = @WorkDate,
                    PersonName = @PersonName,
                    Hours = @Hours,
                    Activity = @Activity,
                    Notes = @Notes,
                    CustomerId = @CustomerId,
                    ServiceItemId = @ServiceItemId,
                    IsBillable = @IsBillable,
                    Status = @Status,
                    UpdatedAt = @UpdatedAt
                WHERE Id = @Id
                """,
                ToParameters(entry),
                cancellationToken);

            return Ok((await ToDtosAsync([entry], cancellationToken)).Single());
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

    [HttpPost("{id:guid}/approve")]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TimeEntryDto>> Approve(Guid id, CancellationToken cancellationToken = default) =>
        await ChangeStatus(id, entry => entry.Approve(), cancellationToken);

    [HttpPost("{id:guid}/mark-invoiced")]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TimeEntryDto>> MarkInvoiced(Guid id, CancellationToken cancellationToken = default) =>
        await ChangeStatus(id, entry => entry.MarkInvoiced(), cancellationToken);

    [HttpPatch("{id:guid}/void")]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TimeEntryDto>> Void(Guid id, CancellationToken cancellationToken = default) =>
        await ChangeStatus(id, entry => entry.Void(), cancellationToken);

    private async Task<ActionResult<TimeEntryDto>> ChangeStatus(Guid id, Action<TimeEntry> action, CancellationToken cancellationToken)
    {
        await EnsureTableAsync(cancellationToken);
        var rows = await QueryTimeEntriesAsync(
            "SELECT Id, CompanyId, WorkDate, PersonName, Hours, Activity, Notes, CustomerId, ServiceItemId, IsBillable, Status, CreatedAt, UpdatedAt FROM time_entries WHERE Id = @Id",
            new Dictionary<string, object?> { ["Id"] = id },
            cancellationToken);
        if (rows.Count == 0) return NotFound();

        try
        {
            var entry = rows.Single();
            action(entry);
            await ExecuteNonQueryAsync(
                "UPDATE time_entries SET Status = @Status, UpdatedAt = @UpdatedAt WHERE Id = @Id",
                ToParameters(entry),
                cancellationToken);
            return Ok((await ToDtosAsync([entry], cancellationToken)).Single());
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    private async Task EnsureTableAsync(CancellationToken cancellationToken)
    {
        await ExecuteNonQueryAsync(
            """
            IF OBJECT_ID(N'time_entries', N'U') IS NULL
            BEGIN
                CREATE TABLE time_entries (
                    Id uniqueidentifier NOT NULL CONSTRAINT PK_time_entries PRIMARY KEY,
                    CompanyId uniqueidentifier NOT NULL,
                    WorkDate date NOT NULL,
                    PersonName nvarchar(160) NOT NULL,
                    Hours decimal(18,2) NOT NULL,
                    Activity nvarchar(200) NOT NULL,
                    Notes nvarchar(1000) NULL,
                    CustomerId uniqueidentifier NULL,
                    ServiceItemId uniqueidentifier NULL,
                    InvoiceId uniqueidentifier NULL,
                    IsBillable bit NOT NULL,
                    Status int NOT NULL,
                    CreatedAt datetimeoffset NOT NULL,
                    UpdatedAt datetimeoffset NULL
                );
                CREATE INDEX IX_time_entries_WorkDate ON time_entries (WorkDate);
                CREATE INDEX IX_time_entries_Status ON time_entries (Status);
                CREATE INDEX IX_time_entries_CustomerId ON time_entries (CustomerId);
                CREATE INDEX IX_time_entries_ServiceItemId ON time_entries (ServiceItemId);
                CREATE INDEX IX_time_entries_InvoiceId ON time_entries (InvoiceId);
            END

            IF OBJECT_ID(N'time_entries', N'U') IS NOT NULL AND COL_LENGTH('time_entries', 'InvoiceId') IS NULL
            BEGIN
                ALTER TABLE time_entries ADD InvoiceId uniqueidentifier NULL;
                CREATE INDEX IX_time_entries_InvoiceId ON time_entries (InvoiceId);
            END
            """,
            new Dictionary<string, object?>(),
            cancellationToken);
    }

    private async Task<string?> ValidateReferencesAsync(Guid? customerId, Guid? serviceItemId, CancellationToken cancellationToken)
    {
        if (customerId is not null && !await _db.Customers.AnyAsync(customer => customer.Id == customerId, cancellationToken))
        {
            return "Customer does not exist.";
        }

        if (serviceItemId is not null && !await _db.Items.AnyAsync(item => item.Id == serviceItemId, cancellationToken))
        {
            return "Service item does not exist.";
        }

        return null;
    }

    private async Task<IReadOnlyList<TimeEntryDto>> ToDtosAsync(IReadOnlyList<TimeEntry> entries, CancellationToken cancellationToken)
    {
        var customerIds = entries.Where(entry => entry.CustomerId is not null).Select(entry => entry.CustomerId!.Value).Distinct().ToList();
        var itemIds = entries.Where(entry => entry.ServiceItemId is not null).Select(entry => entry.ServiceItemId!.Value).Distinct().ToList();
        var entryIds = entries.Select(entry => entry.Id).Distinct().ToList();

        var customers = await _db.Customers.AsNoTracking().Where(customer => customerIds.Contains(customer.Id)).ToDictionaryAsync(customer => customer.Id, customer => customer.DisplayName, cancellationToken);
        var items = await _db.Items.AsNoTracking().Where(item => itemIds.Contains(item.Id)).ToDictionaryAsync(item => item.Id, item => item.Name, cancellationToken);
        var invoiceIds = await GetInvoiceIdsAsync(entryIds, cancellationToken);

        return entries.Select(entry => new TimeEntryDto(
            entry.Id,
            entry.WorkDate,
            entry.PersonName,
            entry.Hours,
            entry.Activity,
            entry.Notes,
            entry.CustomerId,
            entry.CustomerId is not null && customers.TryGetValue(entry.CustomerId.Value, out var customerName) ? customerName : null,
            entry.ServiceItemId,
            entry.ServiceItemId is not null && items.TryGetValue(entry.ServiceItemId.Value, out var itemName) ? itemName : null,
            invoiceIds.TryGetValue(entry.Id, out var invoiceId) ? invoiceId : null,
            entry.IsBillable,
            entry.Status,
            entry.CreatedAt,
            entry.UpdatedAt)).ToList();
    }

    private async Task<IReadOnlyDictionary<Guid, Guid?>> GetInvoiceIdsAsync(IReadOnlyList<Guid> entryIds, CancellationToken cancellationToken)
    {
        var result = new Dictionary<Guid, Guid?>();
        if (entryIds.Count == 0) return result;

        var parameterNames = entryIds.Select((_, index) => $"@EntryId{index}").ToArray();
        var parameters = entryIds.Select((id, index) => new KeyValuePair<string, object?>($"EntryId{index}", id)).ToDictionary(pair => pair.Key, pair => pair.Value);
        var sql = $"SELECT Id, InvoiceId FROM time_entries WHERE Id IN ({string.Join(", ", parameterNames)})";

        await using var command = _db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        AddParameters(command, parameters);
        if (command.Connection!.State != ConnectionState.Open) await command.Connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result[reader.GetGuid(0)] = reader.IsDBNull(1) ? null : reader.GetGuid(1);
        }

        return result;
    }

    private static Dictionary<string, object?> ToParameters(TimeEntry entry) => new()
    {
        ["Id"] = entry.Id,
        ["CompanyId"] = Guid.Parse(CompanyId),
        ["WorkDate"] = entry.WorkDate.ToDateTime(TimeOnly.MinValue),
        ["PersonName"] = entry.PersonName,
        ["Hours"] = entry.Hours,
        ["Activity"] = entry.Activity,
        ["Notes"] = entry.Notes,
        ["CustomerId"] = entry.CustomerId,
        ["ServiceItemId"] = entry.ServiceItemId,
        ["IsBillable"] = entry.IsBillable,
        ["Status"] = (int)entry.Status,
        ["CreatedAt"] = entry.CreatedAt,
        ["UpdatedAt"] = entry.UpdatedAt
    };

    private static void AddFilters(List<string> where, Dictionary<string, object?> parameters, DateOnly? fromDate, DateOnly? toDate, string? search, TimeEntryStatus? status, bool? isBillable)
    {
        if (fromDate is not null)
        {
            where.Add("WorkDate >= @FromDate");
            parameters["FromDate"] = fromDate.Value.ToDateTime(TimeOnly.MinValue);
        }

        if (toDate is not null)
        {
            where.Add("WorkDate <= @ToDate");
            parameters["ToDate"] = toDate.Value.ToDateTime(TimeOnly.MinValue);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            where.Add("(PersonName LIKE @Search OR Activity LIKE @Search)");
            parameters["Search"] = $"%{search.Trim()}%";
        }

        if (status is not null)
        {
            where.Add("Status = @Status");
            parameters["Status"] = (int)status.Value;
        }

        if (isBillable is not null)
        {
            where.Add("IsBillable = @IsBillable");
            parameters["IsBillable"] = isBillable.Value;
        }
    }

    private async Task<object?> ExecuteScalarAsync(string sql, IReadOnlyDictionary<string, object?> parameters, CancellationToken cancellationToken)
    {
        await using var command = _db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        AddParameters(command, parameters);
        if (command.Connection!.State != ConnectionState.Open) await command.Connection.OpenAsync(cancellationToken);
        return await command.ExecuteScalarAsync(cancellationToken);
    }

    private async Task ExecuteNonQueryAsync(string sql, IReadOnlyDictionary<string, object?> parameters, CancellationToken cancellationToken)
    {
        await using var command = _db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        AddParameters(command, parameters);
        if (command.Connection!.State != ConnectionState.Open) await command.Connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private async Task<IReadOnlyList<TimeEntry>> QueryTimeEntriesAsync(string sql, IReadOnlyDictionary<string, object?> parameters, CancellationToken cancellationToken)
    {
        var result = new List<TimeEntry>();
        await using var command = _db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        AddParameters(command, parameters);
        if (command.Connection!.State != ConnectionState.Open) await command.Connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var entry = new TimeEntry(
                DateOnly.FromDateTime(reader.GetDateTime(reader.GetOrdinal("WorkDate"))),
                reader.GetString(reader.GetOrdinal("PersonName")),
                reader.GetDecimal(reader.GetOrdinal("Hours")),
                reader.GetString(reader.GetOrdinal("Activity")),
                reader.IsDBNull(reader.GetOrdinal("Notes")) ? null : reader.GetString(reader.GetOrdinal("Notes")),
                reader.IsDBNull(reader.GetOrdinal("CustomerId")) ? null : reader.GetGuid(reader.GetOrdinal("CustomerId")),
                reader.IsDBNull(reader.GetOrdinal("ServiceItemId")) ? null : reader.GetGuid(reader.GetOrdinal("ServiceItemId")),
                reader.GetBoolean(reader.GetOrdinal("IsBillable")),
                reader.GetGuid(reader.GetOrdinal("CompanyId")));

            typeof(TimeEntry).GetProperty(nameof(TimeEntry.Id))?.SetValue(entry, reader.GetGuid(reader.GetOrdinal("Id")));
            typeof(TimeEntry).GetProperty(nameof(TimeEntry.Status))?.SetValue(entry, (TimeEntryStatus)reader.GetInt32(reader.GetOrdinal("Status")));
            typeof(TimeEntry).GetProperty(nameof(TimeEntry.CreatedAt))?.SetValue(entry, reader.GetFieldValue<DateTimeOffset>(reader.GetOrdinal("CreatedAt")));
            if (!reader.IsDBNull(reader.GetOrdinal("UpdatedAt")))
            {
                typeof(TimeEntry).GetProperty(nameof(TimeEntry.UpdatedAt))?.SetValue(entry, reader.GetFieldValue<DateTimeOffset>(reader.GetOrdinal("UpdatedAt")));
            }

            result.Add(entry);
        }

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
}
