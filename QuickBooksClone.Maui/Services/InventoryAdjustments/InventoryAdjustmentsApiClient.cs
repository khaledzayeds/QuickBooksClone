using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.InventoryAdjustments;

public sealed class InventoryAdjustmentsApiClient
{
    private readonly HttpClient _httpClient;

    public InventoryAdjustmentsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<InventoryAdjustmentListResponse> SearchAsync(string? search, bool includeVoid, CancellationToken cancellationToken = default)
    {
        var url = $"api/inventory-adjustments?includeVoid={includeVoid.ToString().ToLowerInvariant()}&page=1&pageSize=50";
        if (!string.IsNullOrWhiteSpace(search)) url += $"&search={Uri.EscapeDataString(search)}";
        return await _httpClient.GetFromJsonAsync<InventoryAdjustmentListResponse>(url, cancellationToken)
            ?? new InventoryAdjustmentListResponse([], 0, 1, 50);
    }

    public async Task<InventoryAdjustmentDto> CreateAsync(InventoryAdjustmentFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/inventory-adjustments", new
        {
            form.ItemId,
            form.AdjustmentAccountId,
            form.AdjustmentDate,
            form.QuantityChange,
            form.UnitCost,
            form.Reason
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<InventoryAdjustmentDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty inventory adjustment response.");
    }
}
