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

        try
        {
            var runtime = await TryGetRuntimeWithRetryAsync(cancellationToken);
            const string prefix = "Connected successfully.";
            return new ConnectionHealthResult(
                true,
                $"{prefix} {runtime.EnvironmentName} / {runtime.DatabaseProvider}",
                runtime,
                attemptedManagedStartup,
                _localApiProcess.ResolvedProjectPath);
        }
        catch (Exception exception)
        {
            if (allowManagedStartup &&
                settings.StartupMode == ApiStartupMode.ManagedLocalApi &&
                settings.StartupProfile == ApiConnectionMode.Local)
            {
                attemptedManagedStartup = await _localApiProcess.TryEnsureStartedAsync(settings, cancellationToken);
                if (attemptedManagedStartup)
                {
                    try
                    {
                        var runtime = await TryGetRuntimeWithRetryAsync(cancellationToken, 20, 500);
                        return new ConnectionHealthResult(
                            true,
                            $"Local workspace is ready. {runtime.EnvironmentName} / {runtime.DatabaseProvider}",
                            runtime,
                            true,
                            _localApiProcess.ResolvedProjectPath);
                    }
                    catch (Exception retryException)
                    {
                        exception = retryException;
                    }
                }
            }

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

    private async Task<RuntimeSettingsDto> TryGetRuntimeWithRetryAsync(CancellationToken cancellationToken, int attempts = 2, int delayMs = 250)
    {
        Exception? lastException = null;
        for (var index = 0; index < attempts; index++)
        {
            try
            {
                return await _settingsApi.GetRuntimeAsync(cancellationToken);
            }
            catch (Exception exception)
            {
                lastException = exception;
                if (index < attempts - 1)
                {
                    await Task.Delay(delayMs, cancellationToken);
                }
            }
        }

        throw lastException ?? new InvalidOperationException("Could not load runtime settings.");
    }
}
