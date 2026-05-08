using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Contracts.Payroll;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/payroll/reports")]
[RequirePermission("Payroll.View")]
public sealed class PayrollReportsController : ControllerBase
{
    private readonly QuickBooksCloneDbContext _db;

    public PayrollReportsController(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    [HttpGet("summary")]
    [ProducesResponseType(typeof(PayrollSummaryReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<PayrollSummaryReportDto>> Summary([FromQuery] DateOnly? fromDate, [FromQuery] DateOnly? toDate, CancellationToken cancellationToken = default)
    {
        await EnsureTablesAsync(cancellationToken);

        var parameters = new Dictionary<string, object?>
        {
            ["FromDate"] = fromDate?.ToDateTime(TimeOnly.MinValue),
            ["ToDate"] = toDate?.ToDateTime(TimeOnly.MinValue),
        };

        const string where = "WHERE (@FromDate IS NULL OR r.PayDate >= @FromDate) AND (@ToDate IS NULL OR r.PayDate <= @ToDate)";

        var runs = await QueryAsync(
            $"""
            SELECT r.Id, r.RunNumber, r.PeriodStart, r.PeriodEnd, r.PayDate, r.Status, r.Currency, r.JournalEntryId,
                   COUNT(l.Id) EmployeeCount,
                   COALESCE(SUM(l.GrossPay), 0) GrossPay,
                   COALESCE(SUM(l.Deductions), 0) Deductions,
                   COALESCE(SUM(l.NetPay), 0) NetPay
            FROM payroll_runs r
            LEFT JOIN payroll_run_lines l ON l.PayrollRunId = r.Id
            {where}
            GROUP BY r.Id, r.RunNumber, r.PeriodStart, r.PeriodEnd, r.PayDate, r.Status, r.Currency, r.JournalEntryId
            ORDER BY r.PayDate DESC, r.RunNumber DESC
            """,
            parameters,
            reader => new PayrollSummaryRunDto(
                reader.GetGuid(0),
                reader.GetString(1),
                DateOnly.FromDateTime(reader.GetDateTime(2)),
                DateOnly.FromDateTime(reader.GetDateTime(3)),
                DateOnly.FromDateTime(reader.GetDateTime(4)),
                reader.GetString(5),
                reader.GetString(6),
                reader.GetInt32(8),
                reader.GetDecimal(9),
                reader.GetDecimal(10),
                reader.GetDecimal(11),
                reader.IsDBNull(7) ? null : reader.GetGuid(7)),
            cancellationToken);

        var byStatus = await QueryAsync(
            $"""
            SELECT r.Status,
                   COUNT(DISTINCT r.Id) RunCount,
                   COALESCE(SUM(l.GrossPay), 0) GrossPay,
                   COALESCE(SUM(l.Deductions), 0) Deductions,
                   COALESCE(SUM(l.NetPay), 0) NetPay
            FROM payroll_runs r
            LEFT JOIN payroll_run_lines l ON l.PayrollRunId = r.Id
            {where}
            GROUP BY r.Status
            ORDER BY r.Status
            """,
            parameters,
            reader => new PayrollSummaryByStatusDto(
                reader.GetString(0),
                reader.GetInt32(1),
                reader.GetDecimal(2),
                reader.GetDecimal(3),
                reader.GetDecimal(4)),
            cancellationToken);

        var byEmployee = await QueryAsync(
            $"""
            SELECT l.EmployeeId, l.EmployeeNumber, l.EmployeeName,
                   COALESCE(SUM(l.GrossPay), 0) GrossPay,
                   COALESCE(SUM(l.Deductions), 0) Deductions,
                   COALESCE(SUM(l.NetPay), 0) NetPay
            FROM payroll_run_lines l
            INNER JOIN payroll_runs r ON r.Id = l.PayrollRunId
            {where}
            GROUP BY l.EmployeeId, l.EmployeeNumber, l.EmployeeName
            ORDER BY l.EmployeeName
            """,
            parameters,
            reader => new PayrollSummaryByEmployeeDto(
                reader.GetGuid(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetDecimal(3),
                reader.GetDecimal(4),
                reader.GetDecimal(5)),
            cancellationToken);

        var report = new PayrollSummaryReportDto(
            fromDate,
            toDate,
            runs.Count,
            byEmployee.Count,
            runs.Sum(run => run.GrossPay),
            runs.Sum(run => run.Deductions),
            runs.Sum(run => run.NetPay),
            byStatus,
            byEmployee,
            runs);

        return Ok(report);
    }

    private async Task EnsureTablesAsync(CancellationToken cancellationToken)
    {
        await ExecuteNonQueryAsync(
            """
            IF OBJECT_ID(N'payroll_runs', N'U') IS NULL
            BEGIN
                CREATE TABLE payroll_runs (
                    Id uniqueidentifier NOT NULL CONSTRAINT PK_payroll_runs PRIMARY KEY,
                    CompanyId uniqueidentifier NOT NULL,
                    RunNumber nvarchar(40) NOT NULL,
                    PeriodStart date NOT NULL,
                    PeriodEnd date NOT NULL,
                    PayDate date NOT NULL,
                    PaySchedule nvarchar(80) NOT NULL,
                    Currency nvarchar(10) NOT NULL,
                    Status nvarchar(20) NOT NULL,
                    RegularHoursPerEmployee decimal(18,2) NOT NULL,
                    OvertimeHoursPerEmployee decimal(18,2) NOT NULL,
                    TaxWithholdingRate decimal(18,4) NOT NULL,
                    JournalEntryId uniqueidentifier NULL,
                    ReversalJournalEntryId uniqueidentifier NULL,
                    CreatedAt datetimeoffset NOT NULL,
                    UpdatedAt datetimeoffset NULL
                );
            END

            IF OBJECT_ID(N'payroll_run_lines', N'U') IS NULL
            BEGIN
                CREATE TABLE payroll_run_lines (
                    Id uniqueidentifier NOT NULL CONSTRAINT PK_payroll_run_lines PRIMARY KEY,
                    PayrollRunId uniqueidentifier NOT NULL,
                    EmployeeId uniqueidentifier NOT NULL,
                    EmployeeNumber nvarchar(40) NOT NULL,
                    EmployeeName nvarchar(160) NOT NULL,
                    RegularHours decimal(18,2) NOT NULL,
                    OvertimeHours decimal(18,2) NOT NULL,
                    HourlyRate decimal(18,2) NOT NULL,
                    GrossPay decimal(18,2) NOT NULL,
                    Deductions decimal(18,2) NOT NULL,
                    NetPay decimal(18,2) NOT NULL
                );
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
