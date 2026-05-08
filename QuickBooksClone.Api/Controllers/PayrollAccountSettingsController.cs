using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Contracts.Payroll;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/payroll/account-settings")]
[RequirePermission("Payroll.Manage")]
public sealed class PayrollAccountSettingsController : ControllerBase
{
    private const string DefaultCompanyId = "11111111-1111-1111-1111-111111111111";
    private readonly QuickBooksCloneDbContext _db;
    private readonly IAccountRepository _accounts;

    public PayrollAccountSettingsController(QuickBooksCloneDbContext db, IAccountRepository accounts)
    {
        _db = db;
        _accounts = accounts;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PayrollAccountSettingsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<PayrollAccountSettingsDto>> Get(CancellationToken cancellationToken = default)
    {
        await EnsurePayrollAccountColumnsAsync(cancellationToken);
        return Ok(await GetSettingsAsync(cancellationToken));
    }

    [HttpPut]
    [ProducesResponseType(typeof(PayrollAccountSettingsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PayrollAccountSettingsDto>> Update(UpdatePayrollAccountSettingsRequest request, CancellationToken cancellationToken = default)
    {
        await EnsurePayrollAccountColumnsAsync(cancellationToken);

        var validation = await ValidateAccountSelectionAsync(request, cancellationToken);
        if (validation is not null) return BadRequest(validation);

        await ExecuteNonQueryAsync(
            """
            UPDATE payroll_settings
            SET PayrollExpenseAccountId = @PayrollExpenseAccountId,
                PayrollPayableAccountId = @PayrollPayableAccountId,
                PayrollTaxPayableAccountId = @PayrollTaxPayableAccountId,
                UpdatedAt = @UpdatedAt
            WHERE CompanyId = @CompanyId
            """,
            new Dictionary<string, object?>
            {
                ["PayrollExpenseAccountId"] = request.PayrollExpenseAccountId,
                ["PayrollPayableAccountId"] = request.PayrollPayableAccountId,
                ["PayrollTaxPayableAccountId"] = request.PayrollTaxPayableAccountId,
                ["UpdatedAt"] = DateTimeOffset.UtcNow,
                ["CompanyId"] = Guid.Parse(DefaultCompanyId),
            },
            cancellationToken);

        return Ok(await GetSettingsAsync(cancellationToken));
    }

    private async Task<string?> ValidateAccountSelectionAsync(UpdatePayrollAccountSettingsRequest request, CancellationToken cancellationToken)
    {
        if (request.PayrollExpenseAccountId is not null)
        {
            var account = await _accounts.GetByIdAsync(request.PayrollExpenseAccountId.Value, cancellationToken);
            if (account is null || !account.IsActive) return "Payroll expense account must be an active account.";
            if (account.AccountType != AccountType.Expense) return "Payroll expense account must be an Expense account.";
        }

        if (request.PayrollPayableAccountId is not null)
        {
            var account = await _accounts.GetByIdAsync(request.PayrollPayableAccountId.Value, cancellationToken);
            if (account is null || !account.IsActive) return "Payroll payable account must be an active account.";
            if (account.AccountType != AccountType.OtherCurrentLiability) return "Payroll payable account must be an Other Current Liability account.";
        }

        if (request.PayrollTaxPayableAccountId is not null)
        {
            var account = await _accounts.GetByIdAsync(request.PayrollTaxPayableAccountId.Value, cancellationToken);
            if (account is null || !account.IsActive) return "Payroll tax payable account must be an active account.";
            if (account.AccountType != AccountType.OtherCurrentLiability) return "Payroll tax payable account must be an Other Current Liability account.";
        }

        return null;
    }

    private async Task<PayrollAccountSettingsDto> GetSettingsAsync(CancellationToken cancellationToken)
    {
        var rows = await QueryAsync(
            """
            SELECT s.Id,
                   s.PayrollExpenseAccountId,
                   expense.Name AS PayrollExpenseAccountName,
                   s.PayrollPayableAccountId,
                   payable.Name AS PayrollPayableAccountName,
                   s.PayrollTaxPayableAccountId,
                   taxPayable.Name AS PayrollTaxPayableAccountName
            FROM payroll_settings s
            LEFT JOIN Accounts expense ON expense.Id = s.PayrollExpenseAccountId
            LEFT JOIN Accounts payable ON payable.Id = s.PayrollPayableAccountId
            LEFT JOIN Accounts taxPayable ON taxPayable.Id = s.PayrollTaxPayableAccountId
            WHERE s.CompanyId = @CompanyId
            """,
            new Dictionary<string, object?> { ["CompanyId"] = Guid.Parse(DefaultCompanyId) },
            reader => new PayrollAccountSettingsDto(
                reader.GetGuid(0),
                reader.IsDBNull(1) ? null : reader.GetGuid(1),
                reader.IsDBNull(2) ? null : reader.GetString(2),
                reader.IsDBNull(3) ? null : reader.GetGuid(3),
                reader.IsDBNull(4) ? null : reader.GetString(4),
                reader.IsDBNull(5) ? null : reader.GetGuid(5),
                reader.IsDBNull(6) ? null : reader.GetString(6),
                !reader.IsDBNull(1) && !reader.IsDBNull(3) && !reader.IsDBNull(5)),
            cancellationToken);

        return rows.Single();
    }

    private async Task EnsurePayrollAccountColumnsAsync(CancellationToken cancellationToken)
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
                    PayrollExpenseAccountId uniqueidentifier NULL,
                    PayrollPayableAccountId uniqueidentifier NULL,
                    PayrollTaxPayableAccountId uniqueidentifier NULL,
                    CreatedAt datetimeoffset NOT NULL,
                    UpdatedAt datetimeoffset NULL
                );
                CREATE UNIQUE INDEX IX_payroll_settings_CompanyId ON payroll_settings (CompanyId);
            END

            IF NOT EXISTS (SELECT 1 FROM payroll_settings WHERE CompanyId = @CompanyId)
            BEGIN
                INSERT INTO payroll_settings (Id, CompanyId, DefaultPaySchedule, DefaultCurrency, WorkWeekHours, IsPayrollEnabled, CreatedAt, UpdatedAt)
                VALUES (@Id, @CompanyId, 'Biweekly', 'USD', 40, 0, @CreatedAt, NULL)
            END

            IF COL_LENGTH('payroll_settings', 'PayrollExpenseAccountId') IS NULL
            BEGIN
                ALTER TABLE payroll_settings ADD PayrollExpenseAccountId uniqueidentifier NULL;
            END

            IF COL_LENGTH('payroll_settings', 'PayrollPayableAccountId') IS NULL
            BEGIN
                ALTER TABLE payroll_settings ADD PayrollPayableAccountId uniqueidentifier NULL;
            END

            IF COL_LENGTH('payroll_settings', 'PayrollTaxPayableAccountId') IS NULL
            BEGIN
                ALTER TABLE payroll_settings ADD PayrollTaxPayableAccountId uniqueidentifier NULL;
            END
            """,
            new Dictionary<string, object?>
            {
                ["Id"] = Guid.NewGuid(),
                ["CompanyId"] = Guid.Parse(DefaultCompanyId),
                ["CreatedAt"] = DateTimeOffset.UtcNow,
            },
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
