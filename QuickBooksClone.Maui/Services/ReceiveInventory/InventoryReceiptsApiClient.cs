using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.ReceiveInventory;

public sealed class InventoryReceiptsApiClient
{
    private readonly HttpClient _httpClient;
    public InventoryReceiptsApiClient(HttpClient httpClient) => _httpClient = httpClient;

    public async Task<InventoryReceiptListResponse> SearchAsync(string? search, Guid? vendorId, Guid? purchaseOrderId, bool includeVoid, CancellationToken cancellationToken = default)
    {
        var url = $"api/receive-inventory?includeVoid={includeVoid.ToString().ToLowerInvariant()}&page=1&pageSize=50";
        if (!string.IsNullOrWhiteSpace(search)) url += $"&search={Uri.EscapeDataString(search)}";
        if (vendorId is not null) url += $"&vendorId={vendorId}";
        if (purchaseOrderId is not null) url += $"&purchaseOrderId={purchaseOrderId}";
        return await _httpClient.GetFromJsonAsync<InventoryReceiptListResponse>(url, cancellationToken)
            ?? new InventoryReceiptListResponse();
    }

    public async Task<InventoryReceiptDto> GetAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.GetAsync($"api/receive-inventory/{id}", cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<InventoryReceiptDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty inventory receipt response.");
    }

    public async Task<InventoryReceiptDto> CreateAsync(InventoryReceiptFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/receive-inventory", new
        {
            form.VendorId,
            form.PurchaseOrderId,
            form.ReceiptDate,
            form.SaveMode,
            Lines = form.Lines.Select(line => new
            {
                line.ItemId,
                line.PurchaseOrderLineId,
                line.Description,
                line.Quantity,
                line.UnitCost
            })
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<InventoryReceiptDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty inventory receipt response.");
    }

    public async Task<InventoryReceiptDto> PostAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsync($"api/receive-inventory/{id}/post", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<InventoryReceiptDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty inventory receipt response.");
    }

    public async Task<InventoryReceiptDto> VoidAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsync($"api/receive-inventory/{id}/void", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<InventoryReceiptDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty inventory receipt response.");
    }
}
