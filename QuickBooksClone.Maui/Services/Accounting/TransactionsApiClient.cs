using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.Accounting;

public sealed class TransactionsApiClient
{
    private readonly HttpClient _httpClient;

    public TransactionsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<AccountingTransactionListResponse> SearchAsync(
        string? search,
        string? sourceEntityType,
        bool includeVoided,
        CancellationToken cancellationToken = default)
    {
        var url = $"api/transactions?includeVoided={includeVoided.ToString().ToLowerInvariant()}&page=1&pageSize=50";

        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        if (!string.IsNullOrWhiteSpace(sourceEntityType))
        {
            url += $"&sourceEntityType={Uri.EscapeDataString(sourceEntityType)}";
        }

        return await _httpClient.GetFromJsonAsync<AccountingTransactionListResponse>(url, cancellationToken)
            ?? new AccountingTransactionListResponse([], 0, 1, 50);
    }

    public async Task<AccountingTransactionDto> GetAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.GetAsync($"api/transactions/{id}", cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);

        return await response.Content.ReadFromJsonAsync<AccountingTransactionDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty transaction response.");
    }
}
