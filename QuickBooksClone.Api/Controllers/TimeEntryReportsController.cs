using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Contracts.TimeTracking;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.TimeTracking;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/time-entries/reports")]
[RequirePermission("TimeTracking.Manage")]
public sealed class TimeEntryReportsController : ControllerBase
{
    private readonly QuickBooksCloneDbContext _db;

    public TimeEntryReportsController(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    [HttpGet("summary")]
    [ProducesResponseType(typeof(TimeEntrySummaryReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<TimeEntrySummaryReportDto>> Summary([FromQuery] DateOnly? fromDate, [FromQuery] DateOnly? toDate, CancellationToken cancellationToken = default)
    {
        await EnsureTableAsync(cancellationToken);

        var parameters = new Dictionary<string, object?>
        {
            ["FromDate"] = fromDate?.ToDateTime(TimeOnly.MinValue),
            ["ToDate"] = toDate?.ToDateTime(TimeOnly.MinValue),
        };
        const string where = "WHERE (@FromDate IS NULL OR te.WorkDate >= @FromDate) AND (@ToDate IS NULL OR te.WorkDate <= @ToDate)";

        var totals = await QueryAsync(
            $"""
            SELECT COUNT(1),
                   COALESCE(SUM(Hours), 0),
                   COALESCE(SUM(CASE WHEN IsBillable = 1 THEN Hours ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN IsBillable = 0 THEN Hours ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN IsBillable = 1 AND Status IN (@ApprovedStatus, @BillableStatus) THEN Hours ELSE 0 END), 0)
            FROM time_entries te
            {where}
            """,
            WithStatusParameters(parameters),
            reader => new
            {
                EntryCount = reader.GetInt32(0),
                TotalHours = reader.GetDecimal(1),
                BillableHours = reader.GetDecimal(2),
                NonBillableHours = reader.GetDecimal(3),
                BillableNotInvoicedHours = reader.GetDecimal(4),
            },
            cancellationToken);

        var byStatus = await QueryAsync(
            $"""
            SELECT Status,
                   COUNT(1),
                   COALESCE(SUM(Hours), 0),
                   COALESCE(SUM(CASE WHEN IsBillable = 1 THEN Hours ELSE 0 END), 0)
            FROM time_entries te
            {where}
            GROUP BY Status
            ORDER BY Status
            """,
            parameters,
            reader => new TimeEntrySummaryByStatusDto(
                (TimeEntryStatus)reader.GetInt32(0),
                reader.GetInt32(1),
                reader.GetDecimal(2),
                reader.GetDecimal(3)),
            cancellationToken);

        var byPerson = await QueryAsync(
            $"""
            SELECT PersonName,
                   COUNT(1),
                   COALESCE(SUM(Hours), 0),
                   COALESCE(SUM(CASE WHEN IsBillable = 1 THEN Hours ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN Status = @InvoicedStatus THEN Hours ELSE 0 END), 0)
            FROM time_entries te
            {where}
            GROUP BY PersonName
            ORDER BY PersonName
            """,
            WithStatusParameters(parameters),
            reader => new TimeEntrySummaryByPersonDto(
                reader.GetString(0),
                reader.GetInt32(1),
                reader.GetDecimal(2),
                reader.GetDecimal(3),
                reader.GetDecimal(4)),
            cancellationToken);

        var byCustomer = await QueryAsync(
            $"""
            SELECT te.CustomerId,
                   COALESCE(c.DisplayName, 'No customer') CustomerName,
                   COUNT(1),
                   COALESCE(SUM(te.Hours), 0),
                   COALESCE(SUM(CASE WHEN te.IsBillable = 1 THEN te.Hours ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN te.IsBillable = 1 AND te.Status IN (@ApprovedStatus, @BillableStatus) THEN te.Hours ELSE 0 END), 0)
            FROM time_entries te
            LEFT JOIN Customers c ON c.Id = te.CustomerId
            {where}
            GROUP BY te.CustomerId, c.DisplayName
            ORDER BY CustomerName
            """,
            WithStatusParameters(parameters),
            reader => new TimeEntrySummaryByCustomerDto(
                reader.IsDBNull(0) ? null : reader.GetGuid(0),
                reader.GetString(1),
                reader.GetInt32(2),
                reader.GetDecimal(3),
                reader.GetDecimal(4),
                reader.GetDecimal(5)),
            cancellationToken);

        var billableQueue = await QueryAsync(
            $"""
            SELECT te.Id, te.WorkDate, te.PersonName, te.Hours, te.Activity,
                   te.CustomerId, c.DisplayName,
                   te.ServiceItemId, i.Name,
                   te.Status
            FROM time_entries te
            INNER JOIN Customers c ON c.Id = te.CustomerId
            INNER JOIN Items i ON i.Id = te.ServiceItemId
            {where}
              AND te.IsBillable = 1
              AND te.Status IN (@ApprovedStatus, @BillableStatus)
              AND te.CustomerId IS NOT NULL
              AND te.ServiceItemId IS NOT NULL
            ORDER BY te.WorkDate, te.PersonName
            """,
            WithStatusParameters(parameters),
            reader => new BillableTimeQueueItemDto(
                reader.GetGuid(0),
                DateOnly.FromDateTime(reader.GetDateTime(1)),
                reader.GetString(2),
                reader.GetDecimal(3),
                reader.GetString(4),
                reader.GetGuid(5),
                reader.GetString(6),
                reader.GetGuid(7),
                reader.GetString(8),
                (TimeEntryStatus)reader.GetInt32(9)),
            cancellationToken);

        var total = totals.Single();
        return Ok(new TimeEntrySummaryReportDto(
            fromDate,
            toDate,
            total.EntryCount,
            total.TotalHours,
            total.BillableHours,
            total.NonBillableHours,
            total.BillableNotInvoicedHours,
            byStatus,
            byPerson,
            byCustomer,
            billableQueue));
    }

    private static Dictionary<string, object?> WithStatusParameters(Dictionary<string, object?> parameters)
    {
        var copy = new Dictionary<string, object?>(parameters)
        {
            ["ApprovedStatus"] = (int)TimeEntryStatus.Approved,
            ["BillableStatus"] = (int)TimeEntryStatus.Billable,
            ["InvoicedStatus"] = (int)TimeEntryStatus.Invoiced,
        };
        return copy;
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
            END

            IF OBJECT_ID(N'time_entries', N'U') IS NOT NULL AND COL_LENGTH('time_entries', 'InvoiceId') IS NULL
            BEGIN
                ALTER TABLE time_entries ADD InvoiceId uniqueidentifier NULL;
            END
            """,
            new Dictionary<string, object?>(),
            cancellationToken);
    }

    private async Task ExecuteNonQueryAsync(string sql, IReadOnlyDictionary<string, object?> parameters, CancellationToken cancellationToken)
    {
        await using var command = _db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        AddParameters(command, parameters);
        if (command.Connection!.State != ConnectionState.Open) await command.Connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private async Task<IReadOnlyList<T>> QueryAsync<T>(string sql, IReadOnlyDictionary<string, object?> parameters, Func<IDataRecord, T> mapper, CancellationToken cancellationToken)
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
}
