using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.Accounting;

public sealed class AccountsApiClient
{
    private readonly HttpClient _httpClient;

    public AccountsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<AccountListResponse> SearchAsync(string? search, AccountType? accountType, bool includeInactive, CancellationToken cancellationToken = default)
    {
        var url = $"api/accounts?includeInactive={includeInactive.ToString().ToLowerInvariant()}&page=1&pageSize=200";

        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        if (accountType is not null)
        {
            url += $"&accountType={(int)accountType.Value}";
        }

        return await _httpClient.GetFromJsonAsync<AccountListResponse>(url, cancellationToken)
            ?? new AccountListResponse([], 0, 1, 200);
    }

    public async Task<AccountDto> CreateAsync(AccountFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/accounts", new
        {
            form.Code,
            form.Name,
            form.AccountType,
            form.Description,
            form.ParentId
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<AccountDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty account response.");
    }

    public async Task<AccountDto> UpdateAsync(Guid id, AccountFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PutAsJsonAsync($"api/accounts/{id}", new
        {
            form.Code,
            form.Name,
            form.AccountType,
            form.Description,
            form.ParentId
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<AccountDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty account response.");
    }

    public async Task SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsJsonAsync($"api/accounts/{id}/active", new { IsActive = isActive }, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
    }
}
