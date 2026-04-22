using System.Net.Http.Json;
using QuickBooksClone.Api.Contracts.Reports;

namespace QuickBooksClone.Maui.Services.Reports;

public sealed class ReportsApiClient
{
    private readonly HttpClient _httpClient;

    public ReportsApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<TrialBalanceReportDto> GetTrialBalanceAsync(
        DateOnly asOfDate,
        bool includeZeroBalances,
        bool includeInactiveAccounts,
        CancellationToken cancellationToken = default)
    {
        var url =
            $"api/reports/trial-balance?asOfDate={asOfDate:yyyy-MM-dd}" +
            $"&includeZeroBalances={includeZeroBalances.ToString().ToLowerInvariant()}" +
            $"&includeInactiveAccounts={includeInactiveAccounts.ToString().ToLowerInvariant()}";

        return await _httpClient.GetFromJsonAsync<TrialBalanceReportDto>(url, cancellationToken)
            ?? new TrialBalanceReportDto(asOfDate, [], 0m, 0m);
    }

    public async Task<BalanceSheetReportDto> GetBalanceSheetAsync(
        DateOnly asOfDate,
        bool includeZeroBalances,
        bool includeInactiveAccounts,
        CancellationToken cancellationToken = default)
    {
        var url =
            $"api/reports/balance-sheet?asOfDate={asOfDate:yyyy-MM-dd}" +
            $"&includeZeroBalances={includeZeroBalances.ToString().ToLowerInvariant()}" +
            $"&includeInactiveAccounts={includeInactiveAccounts.ToString().ToLowerInvariant()}";

        return await _httpClient.GetFromJsonAsync<BalanceSheetReportDto>(url, cancellationToken)
            ?? new BalanceSheetReportDto(asOfDate, [], 0m, 0m, 0m, 0m);
    }

    public async Task<ProfitAndLossReportDto> GetProfitAndLossAsync(
        DateOnly fromDate,
        DateOnly toDate,
        bool includeZeroBalances,
        bool includeInactiveAccounts,
        CancellationToken cancellationToken = default)
    {
        var url =
            $"api/reports/profit-and-loss?fromDate={fromDate:yyyy-MM-dd}&toDate={toDate:yyyy-MM-dd}" +
            $"&includeZeroBalances={includeZeroBalances.ToString().ToLowerInvariant()}" +
            $"&includeInactiveAccounts={includeInactiveAccounts.ToString().ToLowerInvariant()}";

        return await _httpClient.GetFromJsonAsync<ProfitAndLossReportDto>(url, cancellationToken)
            ?? new ProfitAndLossReportDto(fromDate, toDate, [], 0m, 0m, 0m, 0m, 0m);
    }

    public async Task<AccountsReceivableAgingReportDto> GetAccountsReceivableAgingAsync(
        DateOnly asOfDate,
        bool includeZeroBalances,
        bool includeInactiveCustomers,
        CancellationToken cancellationToken = default)
    {
        var url =
            $"api/reports/accounts-receivable-aging?asOfDate={asOfDate:yyyy-MM-dd}" +
            $"&includeZeroBalances={includeZeroBalances.ToString().ToLowerInvariant()}" +
            $"&includeInactiveCustomers={includeInactiveCustomers.ToString().ToLowerInvariant()}";

        return await _httpClient.GetFromJsonAsync<AccountsReceivableAgingReportDto>(url, cancellationToken)
            ?? new AccountsReceivableAgingReportDto(asOfDate, [], 0m, 0m, 0m, 0m, 0m, 0m);
    }
}
