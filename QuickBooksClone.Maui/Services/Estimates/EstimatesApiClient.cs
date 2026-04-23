using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.Estimates;

public sealed class EstimatesApiClient
{
    private readonly HttpClient _httpClient;
    public EstimatesApiClient(HttpClient httpClient) => _httpClient = httpClient;

    public async Task<EstimateListResponse> SearchAsync(string? search, bool includeClosed, bool includeCancelled, CancellationToken cancellationToken = default)
    {
        var url = $"api/estimates?includeClosed={includeClosed.ToString().ToLowerInvariant()}&includeCancelled={includeCancelled.ToString().ToLowerInvariant()}&page=1&pageSize=50";
        if (!string.IsNullOrWhiteSpace(search)) url += $"&search={Uri.EscapeDataString(search)}";
        return await _httpClient.GetFromJsonAsync<EstimateListResponse>(url, cancellationToken)
            ?? new EstimateListResponse([], 0, 1, 50);
    }

    public async Task<EstimateDto> CreateAsync(EstimateFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/estimates", new
        {
            form.CustomerId,
            form.EstimateDate,
            form.ExpirationDate,
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
        return await response.Content.ReadFromJsonAsync<EstimateDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty estimate response.");
    }

    public async Task<EstimateDto> SendAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsync($"api/estimates/{id}/send", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<EstimateDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty estimate response.");
    }

    public async Task<EstimateDto> AcceptAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsync($"api/estimates/{id}/accept", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<EstimateDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty estimate response.");
    }

    public async Task<EstimateDto> DeclineAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsync($"api/estimates/{id}/decline", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<EstimateDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty estimate response.");
    }

    public async Task<EstimateDto> CancelAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsync($"api/estimates/{id}/cancel", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<EstimateDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty estimate response.");
    }
}
