using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.Payments;

public sealed class PaymentsApiClient
{
    private readonly HttpClient _httpClient;

    public PaymentsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<PaymentListResponse> SearchAsync(string? search, bool includeVoid, CancellationToken cancellationToken = default)
    {
        var url = $"api/payments?includeVoid={includeVoid.ToString().ToLowerInvariant()}&page=1&pageSize=50";

        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        return await _httpClient.GetFromJsonAsync<PaymentListResponse>(url, cancellationToken)
            ?? new PaymentListResponse([], 0, 1, 50);
    }

    public async Task<PaymentDto> CreateAsync(PaymentFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/payments", form, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);

        return await response.Content.ReadFromJsonAsync<PaymentDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty payment response.");
    }

    public async Task<PaymentDto> VoidAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsync($"api/payments/{id}/void", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);

        return await response.Content.ReadFromJsonAsync<PaymentDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty payment response.");
    }
}
