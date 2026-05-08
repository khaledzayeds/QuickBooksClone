using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Contracts;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/payroll/runs/{runId:guid}/journal-links")]
[RequirePermission("Payroll.Manage")]
public sealed class PayrollRunJournalLinksController : ControllerBase
{
    private readonly QuickBooksCloneDbContext _db;

    public PayrollRunJournalLinksController(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    [ProducesResponseType(typeof(RunJournalLinksDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<RunJournalLinksDto>> Get(Guid runId, CancellationToken cancellationToken = default)
    {
        await EnsureColumnAsync(cancellationToken);

        var rows = await QueryAsync(
            """
            SELECT Id, JournalEntryId, ReversalJournalEntryId
            FROM payroll_runs
            WHERE Id = @RunId
            """,
            new Dictionary<string, object?> { ["RunId"] = runId },
            reader => new RunJournalLinksDto(
                reader.GetGuid(0),
                reader.IsDBNull(1) ? null : reader.GetGuid(1),
                reader.IsDBNull(2) ? null : reader.GetGuid(2),
                !reader.IsDBNull(1),
                !reader.IsDBNull(2)),
            cancellationToken);

        var links = rows.SingleOrDefault();
        return links is null ? NotFound() : Ok(links);
    }

    private async Task EnsureColumnAsync(CancellationToken cancellationToken)
    {
        await ExecuteNonQueryAsync(
            """
            IF OBJECT_ID(N'payroll_runs', N'U') IS NOT NULL AND COL_LENGTH('payroll_runs', 'ReversalJournalEntryId') IS NULL
            BEGIN
                ALTER TABLE payroll_runs ADD ReversalJournalEntryId uniqueidentifier NULL;
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
