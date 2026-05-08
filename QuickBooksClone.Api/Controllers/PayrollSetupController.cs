using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Contracts.Payroll;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/payroll/setup")]
[RequirePermission("Payroll.Manage")]
public sealed class PayrollSetupController : ControllerBase
{
    private const string DefaultCompanyId = "11111111-1111-1111-1111-111111111111";
    private readonly QuickBooksCloneDbContext _db;

    public PayrollSetupController(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PayrollSetupDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<PayrollSetupDto>> GetSetup(CancellationToken cancellationToken = default)
    {
        await EnsureTablesAsync(cancellationToken);
        await EnsureDefaultSettingsAsync(cancellationToken);
        await EnsureDefaultTypesAsync(cancellationToken);
        return Ok(await BuildSetupDtoAsync(cancellationToken));
    }

    [HttpPut("settings")]
    [ProducesResponseType(typeof(PayrollSettingsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PayrollSettingsDto>> UpdateSettings(UpdatePayrollSettingsRequest request, CancellationToken cancellationToken = default)
    {
        await EnsureTablesAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(request.DefaultPaySchedule)) return BadRequest("Default pay schedule is required.");
        if (string.IsNullOrWhiteSpace(request.DefaultCurrency)) return BadRequest("Default currency is required.");
        if (request.WorkWeekHours <= 0 || request.WorkWeekHours > 168) return BadRequest("Work week hours must be between 1 and 168.");

        await EnsureDefaultSettingsAsync(cancellationToken);
        await ExecuteNonQueryAsync(
            """
            UPDATE payroll_settings
            SET DefaultPaySchedule = @DefaultPaySchedule,
                DefaultCurrency = @DefaultCurrency,
                WorkWeekHours = @WorkWeekHours,
                IsPayrollEnabled = @IsPayrollEnabled,
                UpdatedAt = @UpdatedAt
            WHERE CompanyId = @CompanyId
            """,
            new Dictionary<string, object?>
            {
                ["DefaultPaySchedule"] = request.DefaultPaySchedule.Trim(),
                ["DefaultCurrency"] = request.DefaultCurrency.Trim().ToUpperInvariant(),
                ["WorkWeekHours"] = request.WorkWeekHours,
                ["IsPayrollEnabled"] = request.IsPayrollEnabled,
                ["UpdatedAt"] = DateTimeOffset.UtcNow,
                ["CompanyId"] = Guid.Parse(DefaultCompanyId),
            },
            cancellationToken);

        return Ok(await GetSettingsAsync(cancellationToken));
    }

    [HttpPost("employees")]
    [ProducesResponseType(typeof(PayrollEmployeeDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<PayrollEmployeeDto>> CreateEmployee(CreatePayrollEmployeeRequest request, CancellationToken cancellationToken = default)
    {
        await EnsureTablesAsync(cancellationToken);
        var validation = ValidateEmployee(request);
        if (validation is not null) return BadRequest(validation);

        var exists = Convert.ToInt32(await ExecuteScalarAsync(
            "SELECT COUNT(1) FROM payroll_employees WHERE EmployeeNumber = @EmployeeNumber",
            new Dictionary<string, object?> { ["EmployeeNumber"] = request.EmployeeNumber.Trim() },
            cancellationToken) ?? 0) > 0;
        if (exists) return Conflict("Employee number already exists.");

        var now = DateTimeOffset.UtcNow;
        var id = Guid.NewGuid();
        await ExecuteNonQueryAsync(
            """
            INSERT INTO payroll_employees (Id, CompanyId, EmployeeNumber, DisplayName, Email, PaySchedule, DefaultHourlyRate, Currency, IsActive, CreatedAt, UpdatedAt)
            VALUES (@Id, @CompanyId, @EmployeeNumber, @DisplayName, @Email, @PaySchedule, @DefaultHourlyRate, @Currency, @IsActive, @CreatedAt, NULL)
            """,
            new Dictionary<string, object?>
            {
                ["Id"] = id,
                ["CompanyId"] = Guid.Parse(DefaultCompanyId),
                ["EmployeeNumber"] = request.EmployeeNumber.Trim(),
                ["DisplayName"] = request.DisplayName.Trim(),
                ["Email"] = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email.Trim(),
                ["PaySchedule"] = request.PaySchedule.Trim(),
                ["DefaultHourlyRate"] = request.DefaultHourlyRate,
                ["Currency"] = request.Currency.Trim().ToUpperInvariant(),
                ["IsActive"] = request.IsActive,
                ["CreatedAt"] = now,
            },
            cancellationToken);

        var employee = (await GetEmployeesAsync(cancellationToken)).Single(current => current.Id == id);
        return CreatedAtAction(nameof(GetSetup), new { id }, employee);
    }

    [HttpPost("earning-types")]
    [ProducesResponseType(typeof(PayrollEarningTypeDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<PayrollEarningTypeDto>> CreateEarningType(CreatePayrollEarningTypeRequest request, CancellationToken cancellationToken = default)
    {
        await EnsureTablesAsync(cancellationToken);
        var validation = ValidateCodeAndName(request.Code, request.Name);
        if (validation is not null) return BadRequest(validation);

        var exists = Convert.ToInt32(await ExecuteScalarAsync(
            "SELECT COUNT(1) FROM payroll_earning_types WHERE Code = @Code",
            new Dictionary<string, object?> { ["Code"] = request.Code.Trim().ToUpperInvariant() },
            cancellationToken) ?? 0) > 0;
        if (exists) return Conflict("Earning type code already exists.");

        var id = Guid.NewGuid();
        await ExecuteNonQueryAsync(
            """
            INSERT INTO payroll_earning_types (Id, CompanyId, Code, Name, IsTaxable, IsActive, CreatedAt, UpdatedAt)
            VALUES (@Id, @CompanyId, @Code, @Name, @IsTaxable, @IsActive, @CreatedAt, NULL)
            """,
            new Dictionary<string, object?>
            {
                ["Id"] = id,
                ["CompanyId"] = Guid.Parse(DefaultCompanyId),
                ["Code"] = request.Code.Trim().ToUpperInvariant(),
                ["Name"] = request.Name.Trim(),
                ["IsTaxable"] = request.IsTaxable,
                ["IsActive"] = request.IsActive,
                ["CreatedAt"] = DateTimeOffset.UtcNow,
            },
            cancellationToken);

        var item = (await GetEarningTypesAsync(cancellationToken)).Single(current => current.Id == id);
        return CreatedAtAction(nameof(GetSetup), new { id }, item);
    }

    [HttpPost("deduction-types")]
    [ProducesResponseType(typeof(PayrollDeductionTypeDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<PayrollDeductionTypeDto>> CreateDeductionType(CreatePayrollDeductionTypeRequest request, CancellationToken cancellationToken = default)
    {
        await EnsureTablesAsync(cancellationToken);
        var validation = ValidateCodeAndName(request.Code, request.Name);
        if (validation is not null) return BadRequest(validation);

        var exists = Convert.ToInt32(await ExecuteScalarAsync(
            "SELECT COUNT(1) FROM payroll_deduction_types WHERE Code = @Code",
            new Dictionary<string, object?> { ["Code"] = request.Code.Trim().ToUpperInvariant() },
            cancellationToken) ?? 0) > 0;
        if (exists) return Conflict("Deduction type code already exists.");

        var id = Guid.NewGuid();
        await ExecuteNonQueryAsync(
            """
            INSERT INTO payroll_deduction_types (Id, CompanyId, Code, Name, IsPreTax, IsActive, CreatedAt, UpdatedAt)
            VALUES (@Id, @CompanyId, @Code, @Name, @IsPreTax, @IsActive, @CreatedAt, NULL)
            """,
            new Dictionary<string, object?>
            {
                ["Id"] = id,
                ["CompanyId"] = Guid.Parse(DefaultCompanyId),
                ["Code"] = request.Code.Trim().ToUpperInvariant(),
                ["Name"] = request.Name.Trim(),
                ["IsPreTax"] = request.IsPreTax,
                ["IsActive"] = request.IsActive,
                ["CreatedAt"] = DateTimeOffset.UtcNow,
            },
            cancellationToken);

        var item = (await GetDeductionTypesAsync(cancellationToken)).Single(current => current.Id == id);
        return CreatedAtAction(nameof(GetSetup), new { id }, item);
    }

    private async Task<PayrollSetupDto> BuildSetupDtoAsync(CancellationToken cancellationToken)
    {
        var settings = await GetSettingsAsync(cancellationToken);
        var employees = await GetEmployeesAsync(cancellationToken);
        var earningTypes = await GetEarningTypesAsync(cancellationToken);
        var deductionTypes = await GetDeductionTypesAsync(cancellationToken);
        return new PayrollSetupDto(
            settings,
            employees,
            earningTypes,
            deductionTypes,
            employees.Count(employee => employee.IsActive),
            employees.Select(employee => employee.PaySchedule).Distinct(StringComparer.OrdinalIgnoreCase).Count());
    }

    private async Task EnsureTablesAsync(CancellationToken cancellationToken)
    {
        await ExecuteNonQueryAsync(
            """
            IF OBJECT_ID(N'payroll_settings', N'U') IS NULL
            BEGIN
                CREATE TABLE payroll_settings (
                    Id uniqueidentifier NOT NULL CONSTRAINT PK_payroll_settings PRIMARY KEY,
                    CompanyId uniqueidentifier NOT NULL,
                    DefaultPaySchedule nvarchar(80) NOT NULL,
                    DefaultCurrency nvarchar(10) NOT NULL,
                    WorkWeekHours int NOT NULL,
                    IsPayrollEnabled bit NOT NULL,
                    CreatedAt datetimeoffset NOT NULL,
                    UpdatedAt datetimeoffset NULL
                );
                CREATE UNIQUE INDEX IX_payroll_settings_CompanyId ON payroll_settings (CompanyId);
            END

            IF OBJECT_ID(N'payroll_employees', N'U') IS NULL
            BEGIN
                CREATE TABLE payroll_employees (
                    Id uniqueidentifier NOT NULL CONSTRAINT PK_payroll_employees PRIMARY KEY,
                    CompanyId uniqueidentifier NOT NULL,
                    EmployeeNumber nvarchar(40) NOT NULL,
                    DisplayName nvarchar(160) NOT NULL,
                    Email nvarchar(250) NULL,
                    PaySchedule nvarchar(80) NOT NULL,
                    DefaultHourlyRate decimal(18,2) NOT NULL,
                    Currency nvarchar(10) NOT NULL,
                    IsActive bit NOT NULL,
                    CreatedAt datetimeoffset NOT NULL,
                    UpdatedAt datetimeoffset NULL
                );
                CREATE UNIQUE INDEX IX_payroll_employees_EmployeeNumber ON payroll_employees (EmployeeNumber);
                CREATE INDEX IX_payroll_employees_DisplayName ON payroll_employees (DisplayName);
            END

            IF OBJECT_ID(N'payroll_earning_types', N'U') IS NULL
            BEGIN
                CREATE TABLE payroll_earning_types (
                    Id uniqueidentifier NOT NULL CONSTRAINT PK_payroll_earning_types PRIMARY KEY,
                    CompanyId uniqueidentifier NOT NULL,
                    Code nvarchar(40) NOT NULL,
                    Name nvarchar(120) NOT NULL,
                    IsTaxable bit NOT NULL,
                    IsActive bit NOT NULL,
                    CreatedAt datetimeoffset NOT NULL,
                    UpdatedAt datetimeoffset NULL
                );
                CREATE UNIQUE INDEX IX_payroll_earning_types_Code ON payroll_earning_types (Code);
            END

            IF OBJECT_ID(N'payroll_deduction_types', N'U') IS NULL
            BEGIN
                CREATE TABLE payroll_deduction_types (
                    Id uniqueidentifier NOT NULL CONSTRAINT PK_payroll_deduction_types PRIMARY KEY,
                    CompanyId uniqueidentifier NOT NULL,
                    Code nvarchar(40) NOT NULL,
                    Name nvarchar(120) NOT NULL,
                    IsPreTax bit NOT NULL,
                    IsActive bit NOT NULL,
                    CreatedAt datetimeoffset NOT NULL,
                    UpdatedAt datetimeoffset NULL
                );
                CREATE UNIQUE INDEX IX_payroll_deduction_types_Code ON payroll_deduction_types (Code);
            END
            """,
            new Dictionary<string, object?>(),
            cancellationToken);
    }

    private async Task EnsureDefaultSettingsAsync(CancellationToken cancellationToken)
    {
        var exists = Convert.ToInt32(await ExecuteScalarAsync(
            "SELECT COUNT(1) FROM payroll_settings WHERE CompanyId = @CompanyId",
            new Dictionary<string, object?> { ["CompanyId"] = Guid.Parse(DefaultCompanyId) },
            cancellationToken) ?? 0) > 0;

        if (exists) return;

        await ExecuteNonQueryAsync(
            """
            INSERT INTO payroll_settings (Id, CompanyId, DefaultPaySchedule, DefaultCurrency, WorkWeekHours, IsPayrollEnabled, CreatedAt, UpdatedAt)
            VALUES (@Id, @CompanyId, @DefaultPaySchedule, @DefaultCurrency, @WorkWeekHours, @IsPayrollEnabled, @CreatedAt, NULL)
            """,
            new Dictionary<string, object?>
            {
                ["Id"] = Guid.NewGuid(),
                ["CompanyId"] = Guid.Parse(DefaultCompanyId),
                ["DefaultPaySchedule"] = "Biweekly",
                ["DefaultCurrency"] = "USD",
                ["WorkWeekHours"] = 40,
                ["IsPayrollEnabled"] = false,
                ["CreatedAt"] = DateTimeOffset.UtcNow,
            },
            cancellationToken);
    }

    private async Task EnsureDefaultTypesAsync(CancellationToken cancellationToken)
    {
        var earningCount = Convert.ToInt32(await ExecuteScalarAsync("SELECT COUNT(1) FROM payroll_earning_types", new Dictionary<string, object?>(), cancellationToken) ?? 0);
        if (earningCount == 0)
        {
            await ExecuteNonQueryAsync(
                """
                INSERT INTO payroll_earning_types (Id, CompanyId, Code, Name, IsTaxable, IsActive, CreatedAt, UpdatedAt)
                VALUES (@RegularId, @CompanyId, 'REG', 'Regular Pay', 1, 1, @CreatedAt, NULL),
                       (@OvertimeId, @CompanyId, 'OT', 'Overtime Pay', 1, 1, @CreatedAt, NULL)
                """,
                new Dictionary<string, object?>
                {
                    ["RegularId"] = Guid.NewGuid(),
                    ["OvertimeId"] = Guid.NewGuid(),
                    ["CompanyId"] = Guid.Parse(DefaultCompanyId),
                    ["CreatedAt"] = DateTimeOffset.UtcNow,
                },
                cancellationToken);
        }

        var deductionCount = Convert.ToInt32(await ExecuteScalarAsync("SELECT COUNT(1) FROM payroll_deduction_types", new Dictionary<string, object?>(), cancellationToken) ?? 0);
        if (deductionCount == 0)
        {
            await ExecuteNonQueryAsync(
                """
                INSERT INTO payroll_deduction_types (Id, CompanyId, Code, Name, IsPreTax, IsActive, CreatedAt, UpdatedAt)
                VALUES (@TaxId, @CompanyId, 'TAX', 'Payroll Tax Withholding', 0, 1, @CreatedAt, NULL),
                       (@BenefitId, @CompanyId, 'BEN', 'Benefits Deduction', 1, 1, @CreatedAt, NULL)
                """,
                new Dictionary<string, object?>
                {
                    ["TaxId"] = Guid.NewGuid(),
                    ["BenefitId"] = Guid.NewGuid(),
                    ["CompanyId"] = Guid.Parse(DefaultCompanyId),
                    ["CreatedAt"] = DateTimeOffset.UtcNow,
                },
                cancellationToken);
        }
    }

    private async Task<PayrollSettingsDto> GetSettingsAsync(CancellationToken cancellationToken)
    {
        var rows = await QueryAsync(
            "SELECT Id, DefaultPaySchedule, DefaultCurrency, WorkWeekHours, IsPayrollEnabled, CreatedAt, UpdatedAt FROM payroll_settings WHERE CompanyId = @CompanyId",
            new Dictionary<string, object?> { ["CompanyId"] = Guid.Parse(DefaultCompanyId) },
            reader => new PayrollSettingsDto(
                reader.GetGuid(0), reader.GetString(1), reader.GetString(2), reader.GetInt32(3), reader.GetBoolean(4), reader.GetFieldValue<DateTimeOffset>(5), reader.IsDBNull(6) ? null : reader.GetFieldValue<DateTimeOffset>(6)),
            cancellationToken);
        return rows.Single();
    }

    private async Task<IReadOnlyList<PayrollEmployeeDto>> GetEmployeesAsync(CancellationToken cancellationToken) =>
        await QueryAsync(
            "SELECT Id, EmployeeNumber, DisplayName, Email, PaySchedule, DefaultHourlyRate, Currency, IsActive, CreatedAt, UpdatedAt FROM payroll_employees ORDER BY DisplayName",
            new Dictionary<string, object?>(),
            reader => new PayrollEmployeeDto(
                reader.GetGuid(0), reader.GetString(1), reader.GetString(2), reader.IsDBNull(3) ? null : reader.GetString(3), reader.GetString(4), reader.GetDecimal(5), reader.GetString(6), reader.GetBoolean(7), reader.GetFieldValue<DateTimeOffset>(8), reader.IsDBNull(9) ? null : reader.GetFieldValue<DateTimeOffset>(9)),
            cancellationToken);

    private async Task<IReadOnlyList<PayrollEarningTypeDto>> GetEarningTypesAsync(CancellationToken cancellationToken) =>
        await QueryAsync(
            "SELECT Id, Code, Name, IsTaxable, IsActive, CreatedAt, UpdatedAt FROM payroll_earning_types ORDER BY Code",
            new Dictionary<string, object?>(),
            reader => new PayrollEarningTypeDto(
                reader.GetGuid(0), reader.GetString(1), reader.GetString(2), reader.GetBoolean(3), reader.GetBoolean(4), reader.GetFieldValue<DateTimeOffset>(5), reader.IsDBNull(6) ? null : reader.GetFieldValue<DateTimeOffset>(6)),
            cancellationToken);

    private async Task<IReadOnlyList<PayrollDeductionTypeDto>> GetDeductionTypesAsync(CancellationToken cancellationToken) =>
        await QueryAsync(
            "SELECT Id, Code, Name, IsPreTax, IsActive, CreatedAt, UpdatedAt FROM payroll_deduction_types ORDER BY Code",
            new Dictionary<string, object?>(),
            reader => new PayrollDeductionTypeDto(
                reader.GetGuid(0), reader.GetString(1), reader.GetString(2), reader.GetBoolean(3), reader.GetBoolean(4), reader.GetFieldValue<DateTimeOffset>(5), reader.IsDBNull(6) ? null : reader.GetFieldValue<DateTimeOffset>(6)),
            cancellationToken);

    private static string? ValidateEmployee(CreatePayrollEmployeeRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.EmployeeNumber)) return "Employee number is required.";
        if (string.IsNullOrWhiteSpace(request.DisplayName)) return "Display name is required.";
        if (string.IsNullOrWhiteSpace(request.PaySchedule)) return "Pay schedule is required.";
        if (string.IsNullOrWhiteSpace(request.Currency)) return "Currency is required.";
        if (request.DefaultHourlyRate < 0) return "Default hourly rate cannot be negative.";
        return null;
    }

    private static string? ValidateCodeAndName(string code, string name)
    {
        if (string.IsNullOrWhiteSpace(code)) return "Code is required.";
        if (string.IsNullOrWhiteSpace(name)) return "Name is required.";
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

    private async Task<IReadOnlyList<T>> QueryAsync<T>(string sql, IReadOnlyDictionary<string, object?> parameters, Func<System.Data.Common.DbDataReader, T> mapper, CancellationToken cancellationToken)
    {
        var result = new List<T>();
        await using var command = _db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        AddParameters(command, parameters);
        if (command.Connection!.State != ConnectionState.Open) await command.Connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(mapper(reader));
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
