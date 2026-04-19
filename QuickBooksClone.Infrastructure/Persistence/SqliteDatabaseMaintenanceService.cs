using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace QuickBooksClone.Infrastructure.Persistence;

public sealed class SqliteDatabaseMaintenanceService : IDatabaseMaintenanceService
{
    private const string SqliteProvider = "Sqlite";

    private readonly QuickBooksCloneDbContext _dbContext;
    private readonly string _provider;
    private readonly string? _liveDatabasePath;
    private readonly string _backupDirectory;

    public SqliteDatabaseMaintenanceService(
        QuickBooksCloneDbContext dbContext,
        IConfiguration configuration)
    {
        _dbContext = dbContext;
        _provider = configuration["Database:Provider"] ?? SqliteProvider;
        var rootPath = Directory.GetCurrentDirectory();

        var connectionString = configuration.GetConnectionString("QuickBooksClone")
            ?? "Data Source=quickbooksclone.db";

        _liveDatabasePath = ResolveSqliteDatabasePath(connectionString, rootPath);
        _backupDirectory = ResolveBackupDirectory(configuration["Database:BackupDirectory"], rootPath);
    }

    public async Task<DatabaseStatus> GetStatusAsync(CancellationToken cancellationToken = default)
    {
        var backups = await ListBackupsAsync(cancellationToken);
        return new DatabaseStatus(
            _provider,
            SupportsBackupRestore(),
            _liveDatabasePath,
            _backupDirectory,
            backups.Count);
    }

    public Task<IReadOnlyList<DatabaseBackupFile>> ListBackupsAsync(CancellationToken cancellationToken = default)
    {
        Directory.CreateDirectory(_backupDirectory);

        IReadOnlyList<DatabaseBackupFile> backups = Directory
            .EnumerateFiles(_backupDirectory, "*.db", SearchOption.TopDirectoryOnly)
            .Select(path => new FileInfo(path))
            .OrderByDescending(file => file.CreationTimeUtc)
            .Select(ToBackupFile)
            .ToList();

        return Task.FromResult(backups);
    }

    public async Task<DatabaseBackupFile> CreateBackupAsync(string? label, CancellationToken cancellationToken = default)
    {
        EnsureSqliteSupported();
        EnsureLiveDatabaseExists();

        Directory.CreateDirectory(_backupDirectory);
        var backupPath = BuildBackupPath(label);

        await _dbContext.Database.CloseConnectionAsync();
        await using var source = CreateSqliteConnection(_liveDatabasePath!);
        await using var destination = CreateSqliteConnection(backupPath);

        await source.OpenAsync(cancellationToken);
        await destination.OpenAsync(cancellationToken);
        source.BackupDatabase(destination);
        await destination.CloseAsync();
        await source.CloseAsync();

        return ToBackupFile(new FileInfo(backupPath));
    }

    public async Task<RestoreDatabaseBackupResult> RestoreBackupAsync(string fileName, bool createSafetyBackup, CancellationToken cancellationToken = default)
    {
        EnsureSqliteSupported();
        EnsureLiveDatabaseExists();

        var backupPath = Path.Combine(_backupDirectory, Path.GetFileName(fileName));
        if (!File.Exists(backupPath))
        {
            throw new FileNotFoundException($"Backup file does not exist: {fileName}");
        }

        ValidateBackupFile(backupPath);

        DatabaseBackupFile? safetyBackup = null;
        if (createSafetyBackup)
        {
            safetyBackup = await CreateBackupAsync("pre-restore", cancellationToken);
        }

        await _dbContext.Database.CloseConnectionAsync();
        await using var source = CreateSqliteConnection(backupPath, readOnly: true);
        await using var destination = CreateSqliteConnection(_liveDatabasePath!);

        await source.OpenAsync(cancellationToken);
        await destination.OpenAsync(cancellationToken);
        source.BackupDatabase(destination);
        await destination.CloseAsync();
        await source.CloseAsync();

        return new RestoreDatabaseBackupResult(ToBackupFile(new FileInfo(backupPath)), safetyBackup);
    }

    private bool SupportsBackupRestore() =>
        _provider.Equals(SqliteProvider, StringComparison.OrdinalIgnoreCase) &&
        !string.IsNullOrWhiteSpace(_liveDatabasePath);

    private void EnsureSqliteSupported()
    {
        if (!SupportsBackupRestore())
        {
            throw new InvalidOperationException("Backup and restore are currently supported only for SQLite mode.");
        }
    }

    private void EnsureLiveDatabaseExists()
    {
        if (string.IsNullOrWhiteSpace(_liveDatabasePath) || !File.Exists(_liveDatabasePath))
        {
            throw new InvalidOperationException("Live SQLite database file does not exist yet.");
        }
    }

    private void ValidateBackupFile(string backupPath)
    {
        using var connection = CreateSqliteConnection(backupPath, readOnly: true);
        connection.Open();

        using var command = connection.CreateCommand();
        command.CommandText = "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = 'accounts';";
        var hasAccountsTable = Convert.ToInt32(command.ExecuteScalar()) > 0;
        if (!hasAccountsTable)
        {
            throw new InvalidOperationException("Backup file is not a valid QuickBooksClone SQLite database.");
        }
    }

    private string BuildBackupPath(string? label)
    {
        var safeLabel = string.IsNullOrWhiteSpace(label)
            ? null
            : string.Join("-", label.Trim().Split(Path.GetInvalidFileNameChars(), StringSplitOptions.RemoveEmptyEntries))
                .Replace(' ', '-');

        var timestamp = DateTimeOffset.UtcNow.ToString("yyyyMMddHHmmss");
        var fileName = string.IsNullOrWhiteSpace(safeLabel)
            ? $"quickbooksclone-backup-{timestamp}.db"
            : $"quickbooksclone-backup-{timestamp}-{safeLabel}.db";

        return Path.Combine(_backupDirectory, fileName);
    }

    private static SqliteConnection CreateSqliteConnection(string databasePath, bool readOnly = false)
    {
        var builder = new SqliteConnectionStringBuilder
        {
            DataSource = databasePath,
            Mode = readOnly ? SqliteOpenMode.ReadOnly : SqliteOpenMode.ReadWriteCreate
        };

        return new SqliteConnection(builder.ToString());
    }

    private static string? ResolveSqliteDatabasePath(string connectionString, string contentRootPath)
    {
        var builder = new SqliteConnectionStringBuilder(connectionString);
        if (string.IsNullOrWhiteSpace(builder.DataSource) || builder.DataSource == ":memory:")
        {
            return null;
        }

        return Path.IsPathRooted(builder.DataSource)
            ? builder.DataSource
            : Path.GetFullPath(Path.Combine(contentRootPath, builder.DataSource));
    }

    private static string ResolveBackupDirectory(string? configuredDirectory, string contentRootPath)
    {
        if (string.IsNullOrWhiteSpace(configuredDirectory))
        {
            return Path.Combine(contentRootPath, "backups");
        }

        return Path.IsPathRooted(configuredDirectory)
            ? configuredDirectory
            : Path.GetFullPath(Path.Combine(contentRootPath, configuredDirectory));
    }

    private static DatabaseBackupFile ToBackupFile(FileInfo file) =>
        new(
            file.Name,
            file.FullName,
            file.Length,
            new DateTimeOffset(file.CreationTimeUtc, TimeSpan.Zero));
}
