using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.SalesOrders;

public sealed class SalesOrdersApiClient
{
    private readonly HttpClient _httpClient;
    public SalesOrdersApiClient(HttpClient httpClient) => _httpClient = httpClient;

    public async Task<SalesOrderListResponse> SearchAsync(string? search, bool includeClosed, bool includeCancelled, CancellationToken cancellationToken = default)
    {
        var url = $"api/sales-orders?includeClosed={includeClosed.ToString().ToLowerInvariant()}&includeCancelled={includeCancelled.ToString().ToLowerInvariant()}&page=1&pageSize=50";
        if (!string.IsNullOrWhiteSpace(search)) url += $"&search={Uri.EscapeDataString(search)}";
        return await _httpClient.GetFromJsonAsync<SalesOrderListResponse>(url, cancellationToken)
            ?? new SalesOrderListResponse([], 0, 1, 50);
    }

    public async Task<SalesOrderDto> CreateAsync(SalesOrderFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/sales-orders", new
        {
            form.CustomerId,
            form.OrderDate,
            form.ExpectedDate,
            form.SaveMode,
            Lines = form.Lines.Select(line => new
            {
                line.ItemId,
                line.Description,
                line.Quantity,
                line.UnitPrice
            })
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<SalesOrderDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty sales order response.");
    }

    public async Task<SalesOrderDto> OpenAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsync($"api/sales-orders/{id}/open", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<SalesOrderDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty sales order response.");
    }

    public async Task<SalesOrderDto> CloseAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsync($"api/sales-orders/{id}/close", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<SalesOrderDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty sales order response.");
    }

    public async Task<SalesOrderDto> CancelAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsync($"api/sales-orders/{id}/cancel", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<SalesOrderDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty sales order response.");
    }
}
