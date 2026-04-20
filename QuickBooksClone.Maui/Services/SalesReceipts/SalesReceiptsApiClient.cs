using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;
using QuickBooksClone.Maui.Services.Invoices;

namespace QuickBooksClone.Maui.Services.SalesReceipts;

public sealed class SalesReceiptsApiClient
{
    private readonly HttpClient _httpClient;

    public SalesReceiptsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<InvoiceListResponse> SearchAsync(string? search, bool includeVoid, CancellationToken cancellationToken = default)
    {
        var url = $"api/sales-receipts?includeVoid={includeVoid.ToString().ToLowerInvariant()}&page=1&pageSize=50";

        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        return await _httpClient.GetFromJsonAsync<InvoiceListResponse>(url, cancellationToken)
            ?? new InvoiceListResponse([], 0, 1, 50);
    }

    public async Task<InvoiceDto> CreateAsync(SalesReceiptFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/sales-receipts", new
        {
            form.CustomerId,
            form.ReceiptDate,
            form.DepositAccountId,
            form.PaymentMethod,
            Lines = form.Lines.Select(line => new
            {
                line.ItemId,
                line.Description,
                line.Quantity,
                line.UnitPrice,
                line.DiscountPercent
            }).ToList()
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<InvoiceDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty sales receipt response.");
    }

    public async Task<InvoiceDto> VoidAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PatchAsync($"api/sales-receipts/{id}/void", null, cancellationToken);
        await response.EnsureQuickBooksSuccessAsync(cancellationToken);

        return await response.Content.ReadFromJsonAsync<InvoiceDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty sales receipt response.");
    }
}
