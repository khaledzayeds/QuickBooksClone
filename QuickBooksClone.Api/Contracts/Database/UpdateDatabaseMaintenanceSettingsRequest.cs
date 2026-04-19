using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.Database;

public sealed record UpdateDatabaseMaintenanceSettingsRequest(
    bool AutoBackupEnabled,
    [Required] string ScheduleMode,
    [Range(0, 23)] int RunAtHourLocal,
    [Range(1, 365)] int RetentionCount,
    bool CreateSafetyBackupBeforeRestore,
    string? PreferredLabelPrefix,
    string? UpdatedBy);
