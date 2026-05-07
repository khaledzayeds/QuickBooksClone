using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Contracts.Payroll;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/payroll/runs")]
[RequirePermission("Payroll.Manage")]
public sealed class PayrollRunsController : ControllerBase
{
    private const string DefaultCompanyId = "11111111-1111-1111-1111-111111111111";
    private readonly QuickBooksCloneDbContext _db;

    public PayrollRunsController(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PayrollRunListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<PayrollRunListResponse>> Search(CancellationToken cancellationToken = default)
    {
        await EnsureTablesAsync(cancellationToken);
        var items = await GetRunSummariesAsync(cancellationToken);
        return Ok(new PayrollRunListResponse(
            items,
            items.Count,
            items.Sum(run => run.TotalGrossPay),
            items.Sum(run => run.TotalDeductions),
            items.Sum(run => run.TotalNetPay)));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(PayrollRunDetailsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PayrollRunDetailsDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        await EnsureTablesAsync(cancellationToken);
        var run = await GetRunDetailsAsync(id, cancellationToken);
        return run is null ? NotFound() : Ok(run);
    }

    [HttpPost]
    [ProducesResponseType(typeof(PayrollRunDetailsDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PayrollRunDetailsDto>> Create(CreatePayrollRunRequest request, CancellationToken cancellationToken = default)
    {
        await EnsureTablesAsync(cancellationToken);
        var validation = ValidateCreateRequest(request);
        if (validation is not null) return BadRequest(validation);

        var employees = await GetActiveEmployeesAsync(request.PaySchedule, cancellationToken);
        if (employees.Count == 0)
        {
            return BadRequest("No active payroll employees found for this pay schedule.");
        }

        var now = DateTimeOffset.UtcNow;
        var runId = Guid.NewGuid();
        var runNumber = await NextRunNumberAsync(cancellationToken);
        var currency = employees.Select(employee => employee.Currency).Distinct(StringComparer.OrdinalIgnoreCase).SingleOrDefault() ?? "USD";

        var lines = employees.Select(employee =>
        {
            var gross = Math.Round((request.RegularHoursPerEmployee * employee.DefaultHourlyRate) + (request.OvertimeHoursPerEmployee * employee.DefaultHourlyRate * 1.5m), 2);
            var deductions = Math.Round(gross * request.TaxWithholdingRate, 2);
            var net = gross - deductions;
            return new PayrollRunLineData(Guid.NewGuid(), runId, employee.Id, employee.EmployeeNumber, employee.DisplayName, request.RegularHoursPerEmployee, request.OvertimeHoursPerEmployee, employee.DefaultHourlyRate, gross, deductions, net);
        }).ToList();

        await ExecuteNonQueryAsync(
            """
            INSERT INTO payroll_runs (Id, CompanyId, RunNumber, PeriodStart, PeriodEnd, PayDate, PaySchedule, Currency, Status, RegularHoursPerEmployee, OvertimeHoursPerEmployee, TaxWithholdingRate, CreatedAt, UpdatedAt)
            VALUES (@Id, @CompanyId, @RunNumber, @PeriodStart, @PeriodEnd, @PayDate, @PaySchedule, @Currency, 'Draft', @RegularHoursPerEmployee, @OvertimeHoursPerEmployee, @TaxWithholdingRate, @CreatedAt, NULL)
            """,
            new Dictionary<string, object?>
            {
                ["Id"] = runId,
                ["CompanyId"] = Guid.Parse(DefaultCompanyId),
                ["RunNumber"] = runNumber,
                ["PeriodStart"] = request.PeriodStart.ToDateTime(TimeOnly.MinValue),
                ["PeriodEnd"] = request.PeriodEnd.ToDateTime(TimeOnly.MinValue),
                ["PayDate"] = request.PayDate.ToDateTime(TimeOnly.MinValue),
                ["PaySchedule"] = request.PaySchedule.Trim(),
                ["Currency"] = currency,
                ["RegularHoursPerEmployee"] = request.RegularHoursPerEmployee,
                ["OvertimeHoursPerEmployee"] = request.OvertimeHoursPerEmployee,
                ["TaxWithholdingRate"] = request.TaxWithholdingRate,
                ["CreatedAt"] = now,
            },
            cancellationToken);

        foreach (var line in lines)
        {
            await ExecuteNonQueryAsync(
                """
                INSERT INTO payroll_run_lines (Id, PayrollRunId, EmployeeId, EmployeeNumber, EmployeeName, RegularHours, OvertimeHours, HourlyRate, GrossPay, Deductions, NetPay)
                VALUES (@Id, @PayrollRunId, @EmployeeId, @EmployeeNumber, @EmployeeName, @RegularHours, @OvertimeHours, @HourlyRate, @GrossPay, @Deductions, @NetPay)
                """,
                new Dictionary<string, object?>
                {
                    ["Id"] = line.Id,
                    ["PayrollRunId"] = line.PayrollRunId,
                    ["EmployeeId"] = line.EmployeeId,
                    ["EmployeeNumber"] = line.EmployeeNumber,
                    ["EmployeeName"] = line.EmployeeName,
                    ["RegularHours"] = line.RegularHours,
                    ["OvertimeHours"] = line.OvertimeHours,
                    ["HourlyRate"] = line.HourlyRate,
                    ["GrossPay"] = line.GrossPay,
                    ["Deductions"] = line.Deductions,
                    ["NetPay"] = line.NetPay,
                },
                cancellationToken);
        }

        var details = await GetRunDetailsAsync(runId, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = runId }, details!);
    }

    [HttpPost("{id:guid}/approve")]
    [ProducesResponseType(typeof(PayrollRunDetailsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<PayrollRunDetailsDto>> Approve(Guid id, CancellationToken cancellationToken = default) =>
        await ChangeStatus(id, ["Draft"], "Approved", cancellationToken);

    [HttpPost("{id:guid}/post")]
    [ProducesResponseType(typeof(PayrollRunDetailsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<PayrollRunDetailsDto>> Post(Guid id, CancellationToken cancellationToken = default) =>
        await ChangeStatus(id, ["Approved"], "Posted", cancellationToken);

    [HttpPatch("{id:guid}/void")]
    [ProducesResponseType(typeof(PayrollRunDetailsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<PayrollRunDetailsDto>> Void(Guid id, CancellationToken cancellationToken = default) =>
        await ChangeStatus(id, ["Draft", "Approved"], "Void", cancellationToken);

    private async Task<ActionResult<PayrollRunDetailsDto>> ChangeStatus(Guid id, IReadOnlyCollection<string> allowedStatuses, string nextStatus, CancellationToken cancellationToken)
    {
        await EnsureTablesAsync(cancellationToken);
        var currentStatus = await ExecuteScalarAsync("SELECT Status FROM payroll_runs WHERE Id = @Id", new Dictionary<string, object?> { ["Id"] = id }, cancellationToken) as string;
        if (currentStatus is null) return NotFound();
        if (!allowedStatuses.Contains(currentStatus, StringComparer.OrdinalIgnoreCase)) return BadRequest($"Payroll run cannot move from {currentStatus} to {nextStatus}.");

        await ExecuteNonQueryAsync(
            "UPDATE payroll_runs SET Status = @Status, UpdatedAt = @UpdatedAt WHERE Id = @Id",
            new Dictionary<string, object?> { ["Id"] = id, ["Status"] = nextStatus, ["UpdatedAt"] = DateTimeOffset.UtcNow },
            cancellationToken);

        return Ok((await GetRunDetailsAsync(id, cancellationToken))!);
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
                    CreatedAt datetimeoffset NOT NULL,
                    UpdatedAt datetimeoffset NULL
                );
                CREATE UNIQUE INDEX IX_payroll_runs_RunNumber ON payroll_runs (RunNumber);
                CREATE INDEX IX_payroll_runs_Period ON payroll_runs (PeriodStart, PeriodEnd);
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
                CREATE INDEX IX_payroll_run_lines_RunId ON payroll_run_lines (PayrollRunId);
            END
            """,
            new Dictionary<string, object?>(),
            cancellationToken);
    }

    private async Task<IReadOnlyList<PayrollEmployeeData>> GetActiveEmployeesAsync(string paySchedule, CancellationToken cancellationToken)
    {
        return await QueryAsync(
            """
            SELECT Id, EmployeeNumber, DisplayName, PaySchedule, DefaultHourlyRate, Currency
            FROM payroll_employees
            WHERE IsActive = 1 AND PaySchedule = @PaySchedule
            ORDER BY DisplayName
            """,
            new Dictionary<string, object?> { ["PaySchedule"] = paySchedule.Trim() },
            reader => new PayrollEmployeeData(reader.GetGuid(0), reader.GetString(1), reader.GetString(2), reader.GetString(3), reader.GetDecimal(4), reader.GetString(5)),
            cancellationToken);
    }

    private async Task<IReadOnlyList<PayrollRunSummaryDto>> GetRunSummariesAsync(CancellationToken cancellationToken) =>
        await QueryAsync(
            """
            SELECT r.Id, r.RunNumber, r.PeriodStart, r.PeriodEnd, r.PayDate, r.PaySchedule, r.Currency, r.Status,
                   COUNT(l.Id) EmployeeCount,
                   COALESCE(SUM(l.GrossPay), 0) TotalGrossPay,
                   COALESCE(SUM(l.Deductions), 0) TotalDeductions,
                   COALESCE(SUM(l.NetPay), 0) TotalNetPay,
                   r.CreatedAt, r.UpdatedAt
            FROM payroll_runs r
            LEFT JOIN payroll_run_lines l ON l.PayrollRunId = r.Id
            GROUP BY r.Id, r.RunNumber, r.PeriodStart, r.PeriodEnd, r.PayDate, r.PaySchedule, r.Currency, r.Status, r.CreatedAt, r.UpdatedAt
            ORDER BY r.CreatedAt DESC
            """,
            new Dictionary<string, object?>(),
            reader => new PayrollRunSummaryDto(
                reader.GetGuid(0),
                reader.GetString(1),
                DateOnly.FromDateTime(reader.GetDateTime(2)),
                DateOnly.FromDateTime(reader.GetDateTime(3)),
                DateOnly.FromDateTime(reader.GetDateTime(4)),
                reader.GetString(5),
                reader.GetString(6),
                reader.GetString(7),
                reader.GetInt32(8),
                reader.GetDecimal(9),
                reader.GetDecimal(10),
                reader.GetDecimal(11),
                reader.GetFieldValue<DateTimeOffset>(12),
                reader.IsDBNull(13) ? null : reader.GetFieldValue<DateTimeOffset>(13)),
            cancellationToken);

    private async Task<PayrollRunDetailsDto?> GetRunDetailsAsync(Guid id, CancellationToken cancellationToken)
    {
        var runRows = await QueryAsync(
            """
            SELECT Id, RunNumber, PeriodStart, PeriodEnd, PayDate, PaySchedule, Currency, Status, RegularHoursPerEmployee, OvertimeHoursPerEmployee, TaxWithholdingRate, CreatedAt, UpdatedAt
            FROM payroll_runs
            WHERE Id = @Id
            """,
            new Dictionary<string, object?> { ["Id"] = id },
            reader => new
            {
                Id = reader.GetGuid(0),
                RunNumber = reader.GetString(1),
                PeriodStart = DateOnly.FromDateTime(reader.GetDateTime(2)),
                PeriodEnd = DateOnly.FromDateTime(reader.GetDateTime(3)),
                PayDate = DateOnly.FromDateTime(reader.GetDateTime(4)),
                PaySchedule = reader.GetString(5),
                Currency = reader.GetString(6),
                Status = reader.GetString(7),
                RegularHours = reader.GetDecimal(8),
                OvertimeHours = reader.GetDecimal(9),
                TaxRate = reader.GetDecimal(10),
                CreatedAt = reader.GetFieldValue<DateTimeOffset>(11),
                UpdatedAt = reader.IsDBNull(12) ? null : reader.GetFieldValue<DateTimeOffset>(12),
            },
            cancellationToken);

        var run = runRows.SingleOrDefault();
        if (run is null) return null;

        var lines = await QueryAsync(
            """
            SELECT Id, EmployeeId, EmployeeNumber, EmployeeName, RegularHours, OvertimeHours, HourlyRate, GrossPay, Deductions, NetPay
            FROM payroll_run_lines
            WHERE PayrollRunId = @Id
            ORDER BY EmployeeName
            """,
            new Dictionary<string, object?> { ["Id"] = id },
            reader => new PayrollRunLineDto(reader.GetGuid(0), reader.GetGuid(1), reader.GetString(2), reader.GetString(3), reader.GetDecimal(4), reader.GetDecimal(5), reader.GetDecimal(6), reader.GetDecimal(7), reader.GetDecimal(8), reader.GetDecimal(9)),
            cancellationToken);

        return new PayrollRunDetailsDto(
            run.Id,
            run.RunNumber,
            run.PeriodStart,
            run.PeriodEnd,
            run.PayDate,
            run.PaySchedule,
            run.Currency,
            run.Status,
            run.RegularHours,
            run.OvertimeHours,
            run.TaxRate,
            lines.Count,
            lines.Sum(line => line.GrossPay),
            lines.Sum(line => line.Deductions),
            lines.Sum(line => line.NetPay),
            lines,
            run.CreatedAt,
            run.UpdatedAt);
    }

    private async Task<string> NextRunNumberAsync(CancellationToken cancellationToken)
    {
        var count = Convert.ToInt32(await ExecuteScalarAsync("SELECT COUNT(1) FROM payroll_runs", new Dictionary<string, object?>(), cancellationToken) ?? 0);
        return $"PR-{DateTime.UtcNow:yyyyMMdd}-{count + 1:0000}";
    }

    private static string? ValidateCreateRequest(CreatePayrollRunRequest request)
    {
        if (request.PeriodStart == default) return "Period start is required.";
        if (request.PeriodEnd == default) return "Period end is required.";
        if (request.PayDate == default) return "Pay date is required.";
        if (request.PeriodEnd < request.PeriodStart) return "Period end cannot be before period start.";
        if (string.IsNullOrWhiteSpace(request.PaySchedule)) return "Pay schedule is required.";
        if (request.RegularHoursPerEmployee < 0 || request.RegularHoursPerEmployee > 240) return "Regular hours must be between 0 and 240.";
        if (request.OvertimeHoursPerEmployee < 0 || request.OvertimeHoursPerEmployee > 120) return "Overtime hours must be between 0 and 120.";
        if (request.TaxWithholdingRate < 0 || request.TaxWithholdingRate > 1) return "Tax withholding rate must be between 0 and 1.";
        return null;
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

    private sealed record PayrollEmployeeData(Guid Id, string EmployeeNumber, string DisplayName, string PaySchedule, decimal DefaultHourlyRate, string Currency);
    private sealed record PayrollRunLineData(Guid Id, Guid PayrollRunId, Guid EmployeeId, string EmployeeNumber, string EmployeeName, decimal RegularHours, decimal OvertimeHours, decimal HourlyRate, decimal GrossPay, decimal Deductions, decimal NetPay);
}
