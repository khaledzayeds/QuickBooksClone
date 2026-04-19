using System.Text.Json;
using Microsoft.Maui.Storage;

namespace QuickBooksClone.Maui.Services;

public sealed class ApiConnectionSettingsStore
{
    private const string PreferencesKey = "api-connection-settings";
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private ApiConnectionSettings _current = new();

    public ApiConnectionSettingsStore()
    {
        _current = Load();
    }

    public ApiConnectionSettings Current => Clone(_current);

    public string CurrentBaseUrl => NormalizeBaseUrl(_current.GetActiveBaseUrl());

    public event Action? Changed;

    public ApiConnectionSettings Save(ApiConnectionSettings settings)
    {
        _current = Clone(settings);
        Preferences.Default.Set(PreferencesKey, JsonSerializer.Serialize(_current, JsonOptions));
        Changed?.Invoke();
        return Current;
    }

    private static ApiConnectionSettings Load()
    {
        var json = Preferences.Default.Get(PreferencesKey, string.Empty);
        if (string.IsNullOrWhiteSpace(json))
        {
            return new ApiConnectionSettings();
        }

        try
        {
            return JsonSerializer.Deserialize<ApiConnectionSettings>(json, JsonOptions) ?? new ApiConnectionSettings();
        }
        catch
        {
            return new ApiConnectionSettings();
        }
    }

    private static ApiConnectionSettings Clone(ApiConnectionSettings settings) =>
        new()
        {
            StartupProfile = settings.StartupProfile,
            LocalUrl = NormalizeBaseUrl(settings.LocalUrl),
            LanUrl = NormalizeBaseUrl(settings.LanUrl),
            HostedUrl = NormalizeBaseUrl(settings.HostedUrl)
        };

    public static string NormalizeBaseUrl(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        return value.Trim().TrimEnd('/');
    }
}
