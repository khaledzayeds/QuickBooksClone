using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.VendorCredits;

public sealed class VendorCreditsApiClient
{
    private readonly HttpClient _httpClient;

    public VendorCreditsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<VendorCreditActivityListResponse> SearchAsync(string? search, Guid? vendorId, VendorCreditAction? action, bool includeVoid, CancellationToken cancellationToken = default)
    {
        var url = $"api/vendor-credits?includeVoid={includeVoid.ToString().ToLowerInvariant()}&page=1&pageSize=50";
        if (!string.IsNullOrWhiteSpace(search)) url += $"&search={Uri.EscapeDataString(search)}";
        if (vendorId is not null) url += $"&vendorId={vendorId.Value}";
        if (action is not null) url += $"&action={(int)action.Value}";
        return await _httpClient.GetFromJsonAsync<VendorCreditActivityListResponse>(url, cancellationToken)
            ?? new VendorCreditActivityListResponse([], 0, 1, 50);
    }

    public async Task<VendorCreditActivityDto> CreateAsync(VendorCreditActivityFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/vendor-credits", new
        {
            form.VendorId,
            form.ActivityDate,
            form.Amount,
            form.Action,
            form.PurchaseBillId,
            form.DepositAccountId,
            form.PaymentMethod
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<VendorCreditActivityDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty vendor credit response.");
    }
}
