namespace QuickBooksClone.Api.Contracts.Database;

public sealed record DatabaseMaintenanceSettingsDto(
    bool AutoBackupEnabled,
    string ScheduleMode,
    int RunAtHourLocal,
    int RetentionCount,
    bool CreateSafetyBackupBeforeRestore,
    string? PreferredLabelPrefix,
    DateTimeOffset? UpdatedAt,
    string? UpdatedBy);
