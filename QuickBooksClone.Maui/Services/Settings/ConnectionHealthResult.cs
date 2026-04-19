namespace QuickBooksClone.Maui.Services.Settings;

public sealed record ConnectionHealthResult(
    bool IsHealthy,
    string Message,
    RuntimeSettingsDto? Runtime = null,
    bool AttemptedManagedStartup = false,
    string? LocalApiProjectPath = null);
