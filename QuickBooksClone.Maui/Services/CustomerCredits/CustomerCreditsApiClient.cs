using System.Net.Http.Json;
using QuickBooksClone.Maui.Services;

namespace QuickBooksClone.Maui.Services.CustomerCredits;

public sealed class CustomerCreditsApiClient
{
    private readonly HttpClient _httpClient;

    public CustomerCreditsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<CustomerCreditActivityListResponse> SearchAsync(string? search, Guid? customerId, CustomerCreditAction? action, bool includeVoid, CancellationToken cancellationToken = default)
    {
        var url = $"api/customer-credits?includeVoid={includeVoid.ToString().ToLowerInvariant()}&page=1&pageSize=50";

        if (!string.IsNullOrWhiteSpace(search))
        {
            url += $"&search={Uri.EscapeDataString(search)}";
        }

        if (customerId is not null)
        {
            url += $"&customerId={customerId.Value}";
        }

        if (action is not null)
        {
            url += $"&action={(int)action.Value}";
        }

        return await _httpClient.GetFromJsonAsync<CustomerCreditActivityListResponse>(url, cancellationToken)
            ?? new CustomerCreditActivityListResponse([], 0, 1, 50);
    }

    public async Task<CustomerCreditActivityDto> CreateAsync(CustomerCreditActivityFormModel form, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("api/customer-credits", new
        {
            form.CustomerId,
            form.ActivityDate,
            form.Amount,
            form.Action,
            form.InvoiceId,
            form.RefundAccountId,
            form.PaymentMethod
        }, cancellationToken);

        await response.EnsureQuickBooksSuccessAsync(cancellationToken);
        return await response.Content.ReadFromJsonAsync<CustomerCreditActivityDto>(cancellationToken)
            ?? throw new InvalidOperationException("API returned an empty customer credit response.");
    }
}
