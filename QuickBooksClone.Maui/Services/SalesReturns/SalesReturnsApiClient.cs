using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.SalesReturns;

public sealed class SalesReturnsApiClient
{
    private readonly HttpClient _httpClient;

    public SalesReturnsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<SalesReturnListResponse> SearchAsync(string? search, Guid? invoiceId, bool includeVoid, CancellationToken cancellationToken = default)
    {
        var url = $"api/sales-returns?includeVoid={includeVoid.ToString().ToLowerInvariant()}&page=1&pageSize=50";

        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        if (invoiceId is not null)
        {
            url += $"&invoiceId={invoiceId.Value}";
        }

        return await _httpClient.GetFromJsonAsync<SalesReturnListResponse>(url, cancellationToken)
            ?? new SalesReturnListResponse([], 0, 1, 50);
    }

    public async Task<SalesReturnDto> CreateAsync(SalesReturnFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/sales-returns", new
        {
            form.InvoiceId,
            form.ReturnDate,
            Lines = form.Lines.Select(line => new
            {
                line.InvoiceLineId,
                line.Quantity,
                line.UnitPrice,
                line.DiscountPercent
            }).ToList()
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<SalesReturnDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty sales return response.");
    }
}
