namespace QuickBooksClone.Maui.Services.Settings;

public sealed class ApiConnectivityService
{
    private readonly ApiConnectionSettingsStore _connectionStore;
    private readonly SettingsApiClient _settingsApi;
    private readonly LocalApiProcessService _localApiProcess;

    public ApiConnectivityService(
        ApiConnectionSettingsStore connectionStore,
        SettingsApiClient settingsApi,
        LocalApiProcessService localApiProcess)
    {
        _connectionStore = connectionStore;
        _settingsApi = settingsApi;
        _localApiProcess = localApiProcess;
    }

    public async Task<ConnectionHealthResult> CheckAsync(bool allowManagedStartup = true, CancellationToken cancellationToken = default)
    {
        var settings = _connectionStore.Current;
        var attemptedManagedStartup = false;

        if (allowManagedStartup &&
            settings.StartupMode == ApiStartupMode.ManagedLocalApi &&
            settings.StartupProfile == ApiConnectionMode.Local)
        {
            attemptedManagedStartup = await _localApiProcess.TryEnsureStartedAsync(settings, cancellationToken);
        }

        try
        {
            var runtime = await _settingsApi.GetRuntimeAsync(cancellationToken);
            var prefix = attemptedManagedStartup ? "Managed local API is running." : "Connected successfully.";
            return new ConnectionHealthResult(
                true,
                $"{prefix} {runtime.EnvironmentName} / {runtime.DatabaseProvider}",
                runtime,
                attemptedManagedStartup,
                _localApiProcess.ResolvedProjectPath);
        }
        catch (Exception exception)
        {
            var message = settings.StartupMode == ApiStartupMode.ManagedLocalApi && settings.StartupProfile == ApiConnectionMode.Local
                ? $"Could not reach the managed local API. {exception.Message}"
                : $"Could not reach the configured API. {exception.Message}";

            if (!string.IsNullOrWhiteSpace(_localApiProcess.LastError))
            {
                message = $"{message} Local startup details: {_localApiProcess.LastError}";
            }

            return new ConnectionHealthResult(
                false,
                message,
                null,
                attemptedManagedStartup,
                _localApiProcess.ResolvedProjectPath);
        }
    }
}
