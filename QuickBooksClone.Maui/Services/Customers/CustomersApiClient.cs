using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.Customers;

public sealed class CustomersApiClient
{
    private readonly HttpClient _httpClient;

    public CustomersApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<CustomerListResponse> SearchAsync(string? search, bool includeInactive, CancellationToken cancellationToken = default)
    {
        var url = $"api/customers?includeInactive={includeInactive.ToString().ToLowerInvariant()}&page=1&pageSize=50";

        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        return await _httpClient.GetFromJsonAsync<CustomerListResponse>(url, cancellationToken)
            ?? new CustomerListResponse([], 0, 1, 50);
    }

    public async Task<CustomerDto> GetAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.GetAsync($"api/customers/{id}", cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);

        return await response.Content.ReadFromJsonAsync<CustomerDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty customer response.");
    }

    public async Task<CustomerDto> CreateAsync(CustomerFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/customers", new
        {
            form.DisplayName,
            form.CompanyName,
            form.Email,
            form.Phone,
            form.Currency,
            form.OpeningBalance
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<CustomerDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty customer response.");
    }

    public async Task<CustomerDto> UpdateAsync(Guid id, CustomerFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PutAsJsonAsync($"api/customers/{id}", new
        {
            form.DisplayName,
            form.CompanyName,
            form.Email,
            form.Phone,
            form.Currency
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<CustomerDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty customer response.");
    }

    public async Task SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsJsonAsync($"api/customers/{id}/active", new { IsActive = isActive }, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
    }
}
