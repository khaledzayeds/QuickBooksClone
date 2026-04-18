using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.Vendors;

public sealed class VendorsApiClient
{
    private readonly HttpClient _httpClient;

    public VendorsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<VendorListResponse> SearchAsync(string? search, bool includeInactive, CancellationToken cancellationToken = default)
    {
        var url = $"api/vendors?includeInactive={includeInactive.ToString().ToLowerInvariant()}&page=1&pageSize=50";

        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        return await _httpClient.GetFromJsonAsync<VendorListResponse>(url, cancellationToken)
            ?? new VendorListResponse([], 0, 1, 50);
    }

    public async Task<VendorDto> GetAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.GetAsync($"api/vendors/{id}", cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);

        return await response.Content.ReadFromJsonAsync<VendorDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty vendor response.");
    }

    public async Task<VendorDto> CreateAsync(VendorFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/vendors", new
        {
            form.DisplayName,
            form.CompanyName,
            form.Email,
            form.Phone,
            form.Currency,
            form.OpeningBalance
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<VendorDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty vendor response.");
    }

    public async Task<VendorDto> UpdateAsync(Guid id, VendorFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PutAsJsonAsync($"api/vendors/{id}", new
        {
            form.DisplayName,
            form.CompanyName,
            form.Email,
            form.Phone,
            form.Currency
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<VendorDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty vendor response.");
    }

    public async Task SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsJsonAsync($"api/vendors/{id}/active", new { IsActive = isActive }, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
    }
}
