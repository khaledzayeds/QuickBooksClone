using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.PurchaseReturns;

public sealed class PurchaseReturnsApiClient
{
    private readonly HttpClient _httpClient;

    public PurchaseReturnsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<PurchaseReturnListResponse> SearchAsync(string? search, bool includeVoid, CancellationToken cancellationToken = default)
    {
        var url = $"api/purchase-returns?includeVoid={includeVoid.ToString().ToLowerInvariant()}&page=1&pageSize=50";
        if (!string.IsNullOrWhiteSpace(search)) url += $"&search={Uri.EscapeDataString(search)}";
        return await _httpClient.GetFromJsonAsync<PurchaseReturnListResponse>(url, cancellationToken)
            ?? new PurchaseReturnListResponse([], 0, 1, 50);
    }

    public async Task<PurchaseReturnDto> CreateAsync(PurchaseReturnFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/purchase-returns", new
        {
            form.PurchaseBillId,
            form.ReturnDate,
            Lines = form.Lines.Select(line => new { line.PurchaseBillLineId, line.Quantity, line.UnitCost }).ToList()
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<PurchaseReturnDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty purchase return response.");
    }
}
