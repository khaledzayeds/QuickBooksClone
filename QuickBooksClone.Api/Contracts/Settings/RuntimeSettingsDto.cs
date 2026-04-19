namespace QuickBooksClone.Api.Contracts.Settings;

public sealed record RuntimeSettingsDto(
    string EnvironmentName,
    string DatabaseProvider,
    bool SupportsBackupRestore,
    string? LiveDatabasePath,
    string BackupDirectory);
