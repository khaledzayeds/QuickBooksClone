using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.Items;

public sealed class ItemsApiClient
{
    private readonly HttpClient _httpClient;

    public ItemsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<ItemListResponse> SearchAsync(string? search, bool includeInactive, CancellationToken cancellationToken = default)
    {
        var url = $"api/items?includeInactive={includeInactive.ToString().ToLowerInvariant()}&page=1&pageSize=50";

        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        return await _httpClient.GetFromJsonAsync<ItemListResponse>(url, cancellationToken)
            ?? new ItemListResponse([], 0, 1, 50);
    }

    public async Task<ItemDto> GetAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.GetAsync($"api/items/{id}", cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);

        return await response.Content.ReadFromJsonAsync<ItemDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty item response.");
    }

    public async Task<ItemDto> CreateAsync(ItemFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/items", new
        {
            form.Name,
            form.ItemType,
            form.Sku,
            form.Barcode,
            form.SalesPrice,
            form.PurchasePrice,
            form.QuantityOnHand,
            form.Unit,
            form.IncomeAccountId,
            form.InventoryAssetAccountId,
            form.CogsAccountId,
            form.ExpenseAccountId
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<ItemDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty item response.");
    }

    public async Task<ItemDto> UpdateAsync(Guid id, ItemFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PutAsJsonAsync($"api/items/{id}", new
        {
            form.Name,
            form.ItemType,
            form.Sku,
            form.Barcode,
            form.SalesPrice,
            form.PurchasePrice,
            form.Unit,
            form.IncomeAccountId,
            form.InventoryAssetAccountId,
            form.CogsAccountId,
            form.ExpenseAccountId
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<ItemDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty item response.");
    }

    public async Task SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsJsonAsync($"api/items/{id}/active", new { IsActive = isActive }, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
    }

    public async Task AdjustQuantityAsync(Guid id, decimal quantityOnHand, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsJsonAsync($"api/items/{id}/quantity", new { QuantityOnHand = quantityOnHand }, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
    }
}
