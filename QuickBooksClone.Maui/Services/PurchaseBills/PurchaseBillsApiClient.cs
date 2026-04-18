using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.PurchaseBills;

public sealed class PurchaseBillsApiClient
{
    private readonly HttpClient _httpClient;

    public PurchaseBillsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<PurchaseBillListResponse> SearchAsync(string? search, bool includeVoid, CancellationToken cancellationToken = default)
    {
        var url = $"api/purchase-bills?includeVoid={includeVoid.ToString().ToLowerInvariant()}&page=1&pageSize=50";

        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        return await _httpClient.GetFromJsonAsync<PurchaseBillListResponse>(url, cancellationToken)
            ?? new PurchaseBillListResponse([], 0, 1, 50);
    }

    public async Task<PurchaseBillDto> CreateAsync(PurchaseBillFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/purchase-bills", new
        {
            form.VendorId,
            form.BillDate,
            form.DueDate,
            form.SaveMode,
            Lines = form.Lines.Select(line => new
            {
                line.ItemId,
                line.Description,
                line.Quantity,
                line.UnitCost
            }).ToList()
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<PurchaseBillDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty purchase bill response.");
    }

    public async Task<PurchaseBillDto> PostAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsync($"api/purchase-bills/{id}/post", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);

        return await response.Content.ReadFromJsonAsync<PurchaseBillDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty purchase bill response.");
    }
}
