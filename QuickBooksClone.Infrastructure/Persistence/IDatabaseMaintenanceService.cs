namespace QuickBooksClone.Infrastructure.Persistence;

public interface IDatabaseMaintenanceService
{
    Task<DatabaseStatus> GetStatusAsync(CancellationToken cancellationToken = default);
    Task<DatabaseMaintenanceSettings> GetMaintenanceSettingsAsync(CancellationToken cancellationToken = default);
    Task<DatabaseMaintenanceSettings> UpdateMaintenanceSettingsAsync(DatabaseMaintenanceSettings settings, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DatabaseBackupFile>> ListBackupsAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DatabaseRestoreAudit>> ListRestoreAuditsAsync(CancellationToken cancellationToken = default);
    Task<DatabaseBackupFile> CreateBackupAsync(string? label, string? requestedBy, string? reason, CancellationToken cancellationToken = default);
    Task<DatabaseBackupFile> ImportBackupAsync(string originalFileName, Stream backupStream, string? label, string? requestedBy, string? reason, CancellationToken cancellationToken = default);
    Task<RestoreDatabaseBackupResult> RestoreBackupAsync(string fileName, bool createSafetyBackup, string? requestedBy, string? reason, CancellationToken cancellationToken = default);
}
