using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using System.Text.Json;

namespace QuickBooksClone.Infrastructure.Persistence;

public sealed class SqliteDatabaseMaintenanceService : IDatabaseMaintenanceService
{
    private const string SqliteProvider = "Sqlite";
    private const string ManualBackupKind = "Manual";
    private const string SafetyBackupKind = "Safety";
    private const string ImportedBackupKind = "Imported";

    private readonly QuickBooksCloneDbContext _dbContext;
    private readonly string _provider;
    private readonly string? _liveDatabasePath;
    private readonly string _backupDirectory;
    private readonly string _settingsPath;
    private readonly string _restoreAuditPath;

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        WriteIndented = true
    };

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
        _settingsPath = Path.Combine(_backupDirectory, "database-maintenance-settings.json");
        _restoreAuditPath = Path.Combine(_backupDirectory, "restore-audit-log.json");
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

    public async Task<DatabaseMaintenanceSettings> GetMaintenanceSettingsAsync(CancellationToken cancellationToken = default)
    {
        Directory.CreateDirectory(_backupDirectory);
        return await ReadSettingsAsync(cancellationToken);
    }

    public async Task<DatabaseMaintenanceSettings> UpdateMaintenanceSettingsAsync(DatabaseMaintenanceSettings settings, CancellationToken cancellationToken = default)
    {
        Directory.CreateDirectory(_backupDirectory);

        var normalized = NormalizeSettings(settings);
        await WriteJsonAsync(_settingsPath, normalized, cancellationToken);
        return normalized;
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

    public async Task<IReadOnlyList<DatabaseRestoreAudit>> ListRestoreAuditsAsync(CancellationToken cancellationToken = default)
    {
        Directory.CreateDirectory(_backupDirectory);
        var audits = await ReadRestoreAuditsAsync(cancellationToken);
        return audits.OrderByDescending(x => x.RestoredAt).ToList();
    }

    public async Task<DatabaseBackupFile> CreateBackupAsync(string? label, string? requestedBy, string? reason, CancellationToken cancellationToken = default)
    {
        EnsureSqliteSupported();
        EnsureLiveDatabaseExists();

        Directory.CreateDirectory(_backupDirectory);
        var settings = await ReadSettingsAsync(cancellationToken);
        var backupPath = BuildBackupPath(label, ManualBackupKind);

        await _dbContext.Database.CloseConnectionAsync();
        await using var source = CreateSqliteConnection(_liveDatabasePath!);
        await using var destination = CreateSqliteConnection(backupPath);

        await source.OpenAsync(cancellationToken);
        await destination.OpenAsync(cancellationToken);
        source.BackupDatabase(destination);
        await destination.CloseAsync();
        await source.CloseAsync();

        var backupFile = ToBackupFile(
            new FileInfo(backupPath),
            new BackupMetadata(
                Label: NormalizeText(label),
                RequestedBy: NormalizeText(requestedBy),
                Reason: NormalizeText(reason),
                BackupKind: ManualBackupKind,
                CreatedAt: DateTimeOffset.UtcNow));

        await WriteBackupMetadataAsync(backupFile, cancellationToken);
        await ApplyRetentionAsync(settings.RetentionCount, cancellationToken);
        return backupFile;
    }

    public async Task<DatabaseBackupFile> ImportBackupAsync(
        string originalFileName,
        Stream backupStream,
        string? label,
        string? requestedBy,
        string? reason,
        CancellationToken cancellationToken = default)
    {
        EnsureSqliteSupported();

        if (string.IsNullOrWhiteSpace(originalFileName))
        {
            throw new InvalidOperationException("Backup file name is required.");
        }

        Directory.CreateDirectory(_backupDirectory);

        var importedLabel = string.IsNullOrWhiteSpace(label)
            ? Path.GetFileNameWithoutExtension(originalFileName)
            : label;

        var importedPath = BuildBackupPath(importedLabel, ImportedBackupKind);
        var tempPath = $"{importedPath}.uploading";

        try
        {
            await using (var destination = File.Create(tempPath))
            {
                await backupStream.CopyToAsync(destination, cancellationToken);
            }

            ValidateBackupFile(tempPath);
            File.Move(tempPath, importedPath, overwrite: true);

            var importedBackup = ToBackupFile(
                new FileInfo(importedPath),
                new BackupMetadata(
                    Label: NormalizeText(importedLabel),
                    RequestedBy: NormalizeText(requestedBy),
                    Reason: NormalizeText(reason),
                    BackupKind: ImportedBackupKind,
                    CreatedAt: DateTimeOffset.UtcNow));

            await WriteBackupMetadataAsync(importedBackup, cancellationToken);
            return importedBackup;
        }
        finally
        {
            if (File.Exists(tempPath))
            {
                File.Delete(tempPath);
            }
        }
    }

    public async Task<RestoreDatabaseBackupResult> RestoreBackupAsync(string fileName, bool createSafetyBackup, string? requestedBy, string? reason, CancellationToken cancellationToken = default)
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
            safetyBackup = await CreateBackupInternalAsync("pre-restore", requestedBy, reason, SafetyBackupKind, cancellationToken);
        }

        await _dbContext.Database.CloseConnectionAsync();
        await using var source = CreateSqliteConnection(backupPath, readOnly: true);
        await using var destination = CreateSqliteConnection(_liveDatabasePath!);

        await source.OpenAsync(cancellationToken);
        await destination.OpenAsync(cancellationToken);
        source.BackupDatabase(destination);
        await destination.CloseAsync();
        await source.CloseAsync();

        var restoredBackup = ToBackupFile(new FileInfo(backupPath));
        var audit = new DatabaseRestoreAudit(
            restoredBackup.FileName,
            restoredBackup.FullPath,
            DateTimeOffset.UtcNow,
            safetyBackup is not null,
            safetyBackup?.FileName,
            NormalizeText(requestedBy),
            NormalizeText(reason),
            _liveDatabasePath,
            _provider);

        var audits = await ReadRestoreAuditsAsync(cancellationToken);
        audits.Add(audit);
        await WriteJsonAsync(_restoreAuditPath, audits, cancellationToken);

        return new RestoreDatabaseBackupResult(restoredBackup, safetyBackup, audit);
    }

    private async Task<DatabaseBackupFile> CreateBackupInternalAsync(
        string? label,
        string? requestedBy,
        string? reason,
        string backupKind,
        CancellationToken cancellationToken)
    {
        EnsureSqliteSupported();
        EnsureLiveDatabaseExists();

        Directory.CreateDirectory(_backupDirectory);
        var backupPath = BuildBackupPath(label, backupKind);

        await _dbContext.Database.CloseConnectionAsync();
        await using var source = CreateSqliteConnection(_liveDatabasePath!);
        await using var destination = CreateSqliteConnection(backupPath);

        await source.OpenAsync(cancellationToken);
        await destination.OpenAsync(cancellationToken);
        source.BackupDatabase(destination);
        await destination.CloseAsync();
        await source.CloseAsync();

        var backupFile = ToBackupFile(
            new FileInfo(backupPath),
            new BackupMetadata(
                Label: NormalizeText(label),
                RequestedBy: NormalizeText(requestedBy),
                Reason: NormalizeText(reason),
                BackupKind: backupKind,
                CreatedAt: DateTimeOffset.UtcNow));

        await WriteBackupMetadataAsync(backupFile, cancellationToken);
        return backupFile;
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

    private async Task ApplyRetentionAsync(int retentionCount, CancellationToken cancellationToken)
    {
        if (retentionCount <= 0)
        {
            return;
        }

        var manualBackups = (await ListBackupsAsync(cancellationToken))
            .Where(x => x.BackupKind == ManualBackupKind)
            .Skip(retentionCount)
            .ToList();

        foreach (var backup in manualBackups)
        {
            await TryDeleteFileWithRetriesAsync(backup.FullPath, cancellationToken);
            await TryDeleteFileWithRetriesAsync(GetBackupMetadataPath(backup.FullPath), cancellationToken);
        }
    }

    private string BuildBackupPath(string? label, string backupKind)
    {
        var safeLabel = string.IsNullOrWhiteSpace(label)
            ? null
            : string.Join("-", label.Trim().Split(Path.GetInvalidFileNameChars(), StringSplitOptions.RemoveEmptyEntries))
                .Replace(' ', '-');

        var timestamp = DateTimeOffset.UtcNow.ToString("yyyyMMddHHmmss");
        var fileName = string.IsNullOrWhiteSpace(safeLabel)
            ? $"quickbooksclone-{backupKind.ToLowerInvariant()}-backup-{timestamp}.db"
            : $"quickbooksclone-{backupKind.ToLowerInvariant()}-backup-{timestamp}-{safeLabel}.db";

        return Path.Combine(_backupDirectory, fileName);
    }

    private async Task<DatabaseMaintenanceSettings> ReadSettingsAsync(CancellationToken cancellationToken)
    {
        if (!File.Exists(_settingsPath))
        {
            return DefaultSettings();
        }

        await using var stream = File.OpenRead(_settingsPath);
        var settings = await JsonSerializer.DeserializeAsync<DatabaseMaintenanceSettings>(stream, JsonOptions, cancellationToken);
        return NormalizeSettings(settings ?? DefaultSettings());
    }

    private async Task<List<DatabaseRestoreAudit>> ReadRestoreAuditsAsync(CancellationToken cancellationToken)
    {
        if (!File.Exists(_restoreAuditPath))
        {
            return [];
        }

        await using var stream = File.OpenRead(_restoreAuditPath);
        return await JsonSerializer.DeserializeAsync<List<DatabaseRestoreAudit>>(stream, JsonOptions, cancellationToken) ?? [];
    }

    private static DatabaseMaintenanceSettings DefaultSettings() =>
        new(
            AutoBackupEnabled: false,
            ScheduleMode: "Daily",
            RunAtHourLocal: 2,
            RetentionCount: 14,
            CreateSafetyBackupBeforeRestore: true,
            PreferredLabelPrefix: null,
            UpdatedAt: null,
            UpdatedBy: null);

    private static DatabaseMaintenanceSettings NormalizeSettings(DatabaseMaintenanceSettings settings) =>
        new(
            settings.AutoBackupEnabled,
            NormalizeScheduleMode(settings.ScheduleMode),
            Math.Clamp(settings.RunAtHourLocal, 0, 23),
            Math.Clamp(settings.RetentionCount, 1, 365),
            settings.CreateSafetyBackupBeforeRestore,
            NormalizeText(settings.PreferredLabelPrefix),
            DateTimeOffset.UtcNow,
            NormalizeText(settings.UpdatedBy));

    private static string NormalizeScheduleMode(string? scheduleMode) =>
        scheduleMode?.Equals("Weekly", StringComparison.OrdinalIgnoreCase) == true
            ? "Weekly"
            : "Daily";

    private static string? NormalizeText(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private async Task WriteBackupMetadataAsync(DatabaseBackupFile backup, CancellationToken cancellationToken)
    {
        var metadata = new BackupMetadata(
            backup.Label,
            backup.RequestedBy,
            backup.Reason,
            backup.BackupKind,
            backup.CreatedAt);

        await WriteJsonAsync(GetBackupMetadataPath(backup.FullPath), metadata, cancellationToken);
    }

    private static string GetBackupMetadataPath(string backupFullPath) => $"{backupFullPath}.json";

    private static async Task WriteJsonAsync<T>(string path, T value, CancellationToken cancellationToken)
    {
        await using var stream = File.Create(path);
        await JsonSerializer.SerializeAsync(stream, value, JsonOptions, cancellationToken);
    }

    private static async Task TryDeleteFileWithRetriesAsync(string path, CancellationToken cancellationToken)
    {
        if (!File.Exists(path))
        {
            return;
        }

        for (var attempt = 0; attempt < 5; attempt++)
        {
            try
            {
                File.Delete(path);
                return;
            }
            catch (IOException) when (attempt < 4)
            {
                await Task.Delay(250, cancellationToken);
            }
            catch (UnauthorizedAccessException) when (attempt < 4)
            {
                await Task.Delay(250, cancellationToken);
            }
        }
    }

    private static SqliteConnection CreateSqliteConnection(string databasePath, bool readOnly = false)
    {
        var builder = new SqliteConnectionStringBuilder
        {
            DataSource = databasePath,
            Mode = readOnly ? SqliteOpenMode.ReadOnly : SqliteOpenMode.ReadWriteCreate,
            Pooling = false
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

    private static DatabaseBackupFile ToBackupFile(FileInfo file)
    {
        var metadata = ReadBackupMetadata(file.FullName);
        return ToBackupFile(file, metadata);
    }

    private static DatabaseBackupFile ToBackupFile(FileInfo file, BackupMetadata? metadata) =>
        new(
            file.Name,
            file.FullName,
            file.Length,
            metadata?.CreatedAt ?? new DateTimeOffset(file.CreationTimeUtc, TimeSpan.Zero),
            metadata?.BackupKind ?? ManualBackupKind,
            metadata?.Label,
            metadata?.RequestedBy,
            metadata?.Reason);

    private static BackupMetadata? ReadBackupMetadata(string backupFullPath)
    {
        var metadataPath = GetBackupMetadataPath(backupFullPath);
        if (!File.Exists(metadataPath))
        {
            return null;
        }

        try
        {
            var json = File.ReadAllText(metadataPath);
            return JsonSerializer.Deserialize<BackupMetadata>(json, JsonOptions);
        }
        catch
        {
            return null;
        }
    }

    private sealed record BackupMetadata(
        string? Label,
        string? RequestedBy,
        string? Reason,
        string BackupKind,
        DateTimeOffset CreatedAt);
}
