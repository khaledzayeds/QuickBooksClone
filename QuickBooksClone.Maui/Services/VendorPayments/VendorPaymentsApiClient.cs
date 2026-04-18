using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.VendorPayments;

public sealed class VendorPaymentsApiClient
{
    private readonly HttpClient _httpClient;

    public VendorPaymentsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<VendorPaymentListResponse> SearchAsync(string? search, bool includeVoid, CancellationToken cancellationToken = default)
    {
        var url = $"api/vendor-payments?includeVoid={includeVoid.ToString().ToLowerInvariant()}&page=1&pageSize=50";

        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        return await _httpClient.GetFromJsonAsync<VendorPaymentListResponse>(url, cancellationToken)
            ?? new VendorPaymentListResponse([], 0, 1, 50);
    }

    public async Task<VendorPaymentDto> CreateAsync(VendorPaymentFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/vendor-payments", form, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);

        return await response.Content.ReadFromJsonAsync<VendorPaymentDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty vendor payment response.");
    }

    public async Task<VendorPaymentDto> VoidAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsync($"api/vendor-payments/{id}/void", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);

        return await response.Content.ReadFromJsonAsync<VendorPaymentDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty vendor payment response.");
    }
}
