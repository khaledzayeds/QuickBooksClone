using System.Net.Http.Json;

namespace QuickBooksClone.Maui.Services.Settings;

public sealed class SettingsApiClient
{
    private readonly HttpClient _httpClient;

    public SettingsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<RuntimeSettingsDto> GetRuntimeAsync(CancellationToken cancellationToken = default)
    {
        return await _httpClient.GetFromJsonAsync<RuntimeSettingsDto>("api/settings/runtime", cancellationToken)
            ?? throw new ApiClientException("Could not load runtime settings.");
    }
}
