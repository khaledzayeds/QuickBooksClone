using System.Data;
using Microsoft.EntityFrameworkCore;
using Zayed.Infrastructure.Persistence;

namespace Zayed.Api.Services;

internal static class TimeEntrySchema
{
    public static async Task EnsureTableAsync(ZayedDbContext db, CancellationToken cancellationToken)
    {
        if (IsSqlite(db))
        {
            await ExecuteNonQueryAsync(
                db,
                """
                CREATE TABLE IF NOT EXISTS time_entries (
                    Id TEXT NOT NULL PRIMARY KEY,
                    CompanyId TEXT NOT NULL,
                    WorkDate TEXT NOT NULL,
                    PersonName TEXT NOT NULL,
                    Hours TEXT NOT NULL,
                    Activity TEXT NOT NULL,
                    Notes TEXT NULL,
                    CustomerId TEXT NULL,
                    ServiceItemId TEXT NULL,
                    InvoiceId TEXT NULL,
                    IsBillable INTEGER NOT NULL,
                    Status INTEGER NOT NULL,
                    CreatedAt TEXT NOT NULL,
                    UpdatedAt TEXT NULL
                );
                CREATE INDEX IF NOT EXISTS IX_time_entries_WorkDate ON time_entries (WorkDate);
                CREATE INDEX IF NOT EXISTS IX_time_entries_Status ON time_entries (Status);
                CREATE INDEX IF NOT EXISTS IX_time_entries_CustomerId ON time_entries (CustomerId);
                CREATE INDEX IF NOT EXISTS IX_time_entries_ServiceItemId ON time_entries (ServiceItemId);
                CREATE INDEX IF NOT EXISTS IX_time_entries_InvoiceId ON time_entries (InvoiceId);
                """,
                cancellationToken);

            await EnsureSqliteColumnAsync(db, "InvoiceId", "TEXT NULL", cancellationToken);
            return;
        }

        await ExecuteNonQueryAsync(
            db,
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
            cancellationToken);
    }

    public static async Task EnsureInvoiceColumnAsync(ZayedDbContext db, CancellationToken cancellationToken)
    {
        await EnsureTableAsync(db, cancellationToken);
    }

    public static bool IsSqlite(ZayedDbContext db) =>
        db.Database.ProviderName?.Contains("Sqlite", StringComparison.OrdinalIgnoreCase) == true;

    private static async Task EnsureSqliteColumnAsync(
        ZayedDbContext db,
        string columnName,
        string columnDefinition,
        CancellationToken cancellationToken)
    {
        if (await SqliteColumnExistsAsync(db, columnName, cancellationToken))
        {
            return;
        }

        await ExecuteNonQueryAsync(db, $"ALTER TABLE time_entries ADD COLUMN {columnName} {columnDefinition};", cancellationToken);
        await ExecuteNonQueryAsync(db, "CREATE INDEX IF NOT EXISTS IX_time_entries_InvoiceId ON time_entries (InvoiceId);", cancellationToken);
    }

    private static async Task<bool> SqliteColumnExistsAsync(ZayedDbContext db, string columnName, CancellationToken cancellationToken)
    {
        await using var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = "PRAGMA table_info(time_entries);";
        if (command.Connection!.State != ConnectionState.Open)
        {
            await command.Connection.OpenAsync(cancellationToken);
        }

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            if (string.Equals(reader.GetString(1), columnName, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        return false;
    }

    private static async Task ExecuteNonQueryAsync(ZayedDbContext db, string sql, CancellationToken cancellationToken)
    {
        await using var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        if (command.Connection!.State != ConnectionState.Open)
        {
            await command.Connection.OpenAsync(cancellationToken);
        }

        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
