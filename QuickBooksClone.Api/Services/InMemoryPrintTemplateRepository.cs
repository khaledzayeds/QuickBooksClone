using System.Data;
using System.Data.Common;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.PrintTemplates;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Services;

public sealed class InMemoryPrintTemplateRepository : IPrintTemplateRepository
{
    private readonly IServiceScopeFactory _scopeFactory;

    public InMemoryPrintTemplateRepository(IServiceScopeFactory scopeFactory)
    {
        _scopeFactory = scopeFactory;
    }

    public async Task<IReadOnlyList<PrintTemplate>> ListAsync(string? documentType, CancellationToken cancellationToken = default)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<QuickBooksCloneDbContext>();
        await EnsureTableAsync(db, cancellationToken);
        var items = new List<PrintTemplate>();
        var sql = string.IsNullOrWhiteSpace(documentType)
            ? "SELECT id, name, document_type, page_size, json_content, is_default, created_at, updated_at FROM print_templates ORDER BY document_type, is_default DESC, name"
            : "SELECT id, name, document_type, page_size, json_content, is_default, created_at, updated_at FROM print_templates WHERE lower(document_type) = lower($documentType) ORDER BY is_default DESC, name";
        await using var command = CreateCommand(db, sql);
        if (!string.IsNullOrWhiteSpace(documentType)) AddParameter(command, "$documentType", documentType.Trim());
        await OpenAsync(command.Connection!, cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) items.Add(ReadTemplate(reader));
        return items;
    }

    public async Task<PrintTemplate?> GetAsync(Guid id, CancellationToken cancellationToken = default)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<QuickBooksCloneDbContext>();
        await EnsureTableAsync(db, cancellationToken);
        await using var command = CreateCommand(db, "SELECT id, name, document_type, page_size, json_content, is_default, created_at, updated_at FROM print_templates WHERE id = $id");
        AddParameter(command, "$id", id.ToString());
        await OpenAsync(command.Connection!, cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? ReadTemplate(reader) : null;
    }

    public async Task<PrintTemplate> AddAsync(PrintTemplate template, CancellationToken cancellationToken = default)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<QuickBooksCloneDbContext>();
        await EnsureTableAsync(db, cancellationToken);
        if (template.IsDefault) await ClearDefaultAsync(db, template.DocumentType, cancellationToken);
        await using var command = CreateCommand(db, "INSERT INTO print_templates (id, name, document_type, page_size, json_content, is_default, created_at, updated_at) VALUES ($id, $name, $documentType, $pageSize, $jsonContent, $isDefault, $createdAt, $updatedAt)");
        BindTemplate(command, template);
        await OpenAsync(command.Connection!, cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return template;
    }

    public async Task<PrintTemplate> UpdateAsync(PrintTemplate template, CancellationToken cancellationToken = default)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<QuickBooksCloneDbContext>();
        await EnsureTableAsync(db, cancellationToken);
        if (template.IsDefault) await ClearDefaultAsync(db, template.DocumentType, cancellationToken);
        await using var command = CreateCommand(db, "UPDATE print_templates SET name = $name, document_type = $documentType, page_size = $pageSize, json_content = $jsonContent, is_default = $isDefault, updated_at = $updatedAt WHERE id = $id");
        BindTemplate(command, template);
        await OpenAsync(command.Connection!, cancellationToken);
        var affected = await command.ExecuteNonQueryAsync(cancellationToken);
        if (affected == 0) throw new KeyNotFoundException("Print template was not found.");
        return template;
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<QuickBooksCloneDbContext>();
        await EnsureTableAsync(db, cancellationToken);
        await using var command = CreateCommand(db, "DELETE FROM print_templates WHERE id = $id");
        AddParameter(command, "$id", id.ToString());
        await OpenAsync(command.Connection!, cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task EnsureTableAsync(QuickBooksCloneDbContext db, CancellationToken cancellationToken)
    {
        await db.Database.ExecuteSqlRawAsync("CREATE TABLE IF NOT EXISTS print_templates (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, document_type TEXT NOT NULL, page_size TEXT NOT NULL, json_content TEXT NOT NULL, is_default INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);", cancellationToken);
        await db.Database.ExecuteSqlRawAsync("CREATE INDEX IF NOT EXISTS idx_print_templates_document_type ON print_templates (document_type);", cancellationToken);
    }

    private static async Task ClearDefaultAsync(QuickBooksCloneDbContext db, string documentType, CancellationToken cancellationToken)
    {
        await using var command = CreateCommand(db, "UPDATE print_templates SET is_default = 0 WHERE lower(document_type) = lower($documentType)");
        AddParameter(command, "$documentType", documentType);
        await OpenAsync(command.Connection!, cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static DbCommand CreateCommand(QuickBooksCloneDbContext db, string sql)
    {
        var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        command.CommandType = CommandType.Text;
        return command;
    }

    private static async Task OpenAsync(DbConnection connection, CancellationToken cancellationToken)
    {
        if (connection.State != ConnectionState.Open) await connection.OpenAsync(cancellationToken);
    }

    private static void BindTemplate(DbCommand command, PrintTemplate template)
    {
        AddParameter(command, "$id", template.Id.ToString());
        AddParameter(command, "$name", template.Name);
        AddParameter(command, "$documentType", template.DocumentType);
        AddParameter(command, "$pageSize", template.PageSize);
        AddParameter(command, "$jsonContent", template.JsonContent);
        AddParameter(command, "$isDefault", template.IsDefault ? 1 : 0);
        AddParameter(command, "$createdAt", template.CreatedAt.ToString("O"));
        AddParameter(command, "$updatedAt", template.UpdatedAt.ToString("O"));
    }

    private static void AddParameter(DbCommand command, string name, object value)
    {
        var parameter = command.CreateParameter();
        parameter.ParameterName = name;
        parameter.Value = value;
        command.Parameters.Add(parameter);
    }

    private static PrintTemplate ReadTemplate(DbDataReader reader)
    {
        return new PrintTemplate(
            Guid.Parse(reader.GetString(0)),
            reader.GetString(1),
            reader.GetString(2),
            reader.GetString(3),
            reader.GetString(4),
            reader.GetInt32(5) == 1,
            DateTime.Parse(reader.GetString(6), null, System.Globalization.DateTimeStyles.RoundtripKind),
            DateTime.Parse(reader.GetString(7), null, System.Globalization.DateTimeStyles.RoundtripKind));
    }
}
