using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.PurchaseOrders;

public sealed class PurchaseOrdersApiClient
{
    private readonly HttpClient _httpClient;
    public PurchaseOrdersApiClient(HttpClient httpClient) => _httpClient = httpClient;

    public async Task<PurchaseOrderListResponse> SearchAsync(string? search, bool includeClosed, bool includeCancelled, CancellationToken cancellationToken = default)
    {
        var url = $"api/purchase-orders?includeClosed={includeClosed.ToString().ToLowerInvariant()}&includeCancelled={includeCancelled.ToString().ToLowerInvariant()}&page=1&pageSize=50";
        if (!string.IsNullOrWhiteSpace(search)) url += $"&search={Uri.EscapeDataString(search)}";
        return await _httpClient.GetFromJsonAsync<PurchaseOrderListResponse>(url, cancellationToken)
            ?? new PurchaseOrderListResponse([], 0, 1, 50);
    }

    public async Task<PurchaseOrderDto> CreateAsync(PurchaseOrderFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/purchase-orders", new
        {
            form.VendorId,
            form.OrderDate,
            form.ExpectedDate,
            form.SaveMode,
            Lines = form.Lines.Select(line => new
            {
                line.ItemId,
                line.Description,
                line.Quantity,
                line.UnitCost
            })
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<PurchaseOrderDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty purchase order response.");
    }

    public async Task<PurchaseOrderDto> OpenAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsync($"api/purchase-orders/{id}/open", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<PurchaseOrderDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty purchase order response.");
    }

    public async Task<PurchaseOrderDto> CloseAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsync($"api/purchase-orders/{id}/close", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<PurchaseOrderDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty purchase order response.");
    }

    public async Task<PurchaseOrderDto> CancelAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsync($"api/purchase-orders/{id}/cancel", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<PurchaseOrderDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty purchase order response.");
    }
}
