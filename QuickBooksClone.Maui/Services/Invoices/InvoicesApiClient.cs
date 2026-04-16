using System.Net.Http.Json;

namespace QuickBooksClone.Maui.Services.Invoices;

public sealed class InvoicesApiClient
{
    private readonly HttpClient _httpClient;

    public InvoicesApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<InvoiceListResponse> SearchAsync(string? search, bool includeVoid, CancellationToken cancellationToken = default)
    {
        var url = $"api/invoices?includeVoid={includeVoid.ToString().ToLowerInvariant()}&page=1&pageSize=50";

        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        return await _httpClient.GetFromJsonAsync<InvoiceListResponse>(url, cancellationToken)
            ?? new InvoiceListResponse([], 0, 1, 50);
    }

    public async Task<InvoiceDto> CreateAsync(InvoiceFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/invoices", new
        {
            form.CustomerId,
            form.InvoiceDate,
            form.DueDate,
            Lines = form.Lines.Select(line => new
            {
                line.ItemId,
                line.Description,
                line.Quantity,
                line.UnitPrice,
                line.DiscountPercent
            }).ToList()
        }, cancellationToken);

        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<InvoiceDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty invoice response.");
    }

    public async Task MarkSentAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsync($"api/invoices/{id}/sent", null, cancellationToken);
        response.EnsureSuccessStatusCode();
    }

    public async Task VoidAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsync($"api/invoices/{id}/void", null, cancellationToken);
        response.EnsureSuccessStatusCode();
    }
}
