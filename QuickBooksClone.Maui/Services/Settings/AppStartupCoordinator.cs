namespace QuickBooksClone.Maui.Services.Settings;

public sealed class AppStartupCoordinator
{
    private readonly ApiConnectivityService _connectivity;
    private readonly ApiConnectionSettingsStore _settingsStore;
    private readonly SemaphoreSlim _gate = new(1, 1);

    public AppStartupCoordinator(ApiConnectivityService connectivity, ApiConnectionSettingsStore settingsStore)
    {
        _connectivity = connectivity;
        _settingsStore = settingsStore;
        CurrentProfileLabel = GetProfileLabel(_settingsStore.Current);
        _settingsStore.Changed += HandleSettingsChanged;
    }

    public event Action? Changed;

    public AppStartupState State { get; private set; } = AppStartupState.NotStarted;
    public ConnectionHealthResult? LastHealth { get; private set; }
    public string CurrentProfileLabel { get; private set; }
    public bool IsReady => State == AppStartupState.Ready;
    public bool IsStarting => State == AppStartupState.Starting;

    public async Task<ConnectionHealthResult> EnsureReadyAsync(CancellationToken cancellationToken = default)
    {
        if (LastHealth?.IsHealthy == true && State == AppStartupState.Ready)
        {
            return LastHealth;
        }

        await _gate.WaitAsync(cancellationToken);
        try
        {
            if (LastHealth?.IsHealthy == true && State == AppStartupState.Ready)
            {
                return LastHealth;
            }

            State = AppStartupState.Starting;
            CurrentProfileLabel = GetProfileLabel(_settingsStore.Current);
            Changed?.Invoke();

            LastHealth = await _connectivity.CheckAsync(true, cancellationToken);
            State = LastHealth.IsHealthy ? AppStartupState.Ready : AppStartupState.Offline;
            Changed?.Invoke();
            return LastHealth;
        }
        finally
        {
            _gate.Release();
        }
    }

    public void Reset()
    {
        LastHealth = null;
        State = AppStartupState.NotStarted;
        CurrentProfileLabel = GetProfileLabel(_settingsStore.Current);
        Changed?.Invoke();
    }

    private void HandleSettingsChanged()
    {
        Reset();
    }

    private static string GetProfileLabel(ApiConnectionSettings settings) =>
        settings.StartupMode == ApiStartupMode.ManagedLocalApi && settings.StartupProfile == ApiConnectionMode.Local
            ? "Local company"
            : settings.StartupProfile switch
            {
                ApiConnectionMode.Lan => "LAN company",
                ApiConnectionMode.Hosted => "Hosted company",
                _ => "Local company"
            };
}
