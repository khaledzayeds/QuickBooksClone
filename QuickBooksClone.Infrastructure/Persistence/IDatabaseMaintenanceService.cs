namespace QuickBooksClone.Infrastructure.Persistence;

public interface IDatabaseMaintenanceService
{
    Task<DatabaseStatus> GetStatusAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DatabaseBackupFile>> ListBackupsAsync(CancellationToken cancellationToken = default);
    Task<DatabaseBackupFile> CreateBackupAsync(string? label, CancellationToken cancellationToken = default);
    Task<RestoreDatabaseBackupResult> RestoreBackupAsync(string fileName, bool createSafetyBackup, CancellationToken cancellationToken = default);
}
