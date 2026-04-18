using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.JournalEntries;

public sealed class JournalEntriesApiClient
{
    private readonly HttpClient _httpClient;

    public JournalEntriesApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<JournalEntryListResponse> SearchAsync(string? search, bool includeVoid, CancellationToken cancellationToken = default)
    {
        var url = $"api/journal-entries?includeVoid={includeVoid.ToString().ToLowerInvariant()}&page=1&pageSize=50";
        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        return await _httpClient.GetFromJsonAsync<JournalEntryListResponse>(url, cancellationToken)
            ?? new JournalEntryListResponse([], 0, 1, 50);
    }

    public async Task<JournalEntryDto> CreateAsync(JournalEntryFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/journal-entries", new
        {
            form.EntryDate,
            form.Memo,
            form.SaveMode,
            form.Lines
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<JournalEntryDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty journal entry response.");
    }

    public async Task<JournalEntryDto> PostAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsync($"api/journal-entries/{id}/post", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<JournalEntryDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty journal entry response.");
    }

    public async Task<JournalEntryDto> VoidAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsync($"api/journal-entries/{id}/void", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<JournalEntryDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty journal entry response.");
    }
}
