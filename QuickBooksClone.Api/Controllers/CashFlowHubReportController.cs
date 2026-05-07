using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Reports;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Reports;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/reports/cash-flow-hub")]
[RequirePermission("Reports.View")]
public sealed class CashFlowHubReportController : ControllerBase
{
    private readonly IFinancialReportService _reports;

    public CashFlowHubReportController(IFinancialReportService reports)
    {
        _reports = reports;
    }

    [HttpGet]
    [ProducesResponseType(typeof(CashFlowHubReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<CashFlowHubReportDto>> GetCashFlowHub(
        [FromQuery] DateOnly? asOfDate,
        [FromQuery] DateOnly? fromDate,
        CancellationToken cancellationToken = default)
    {
        var resolvedAsOfDate = asOfDate ?? DateOnly.FromDateTime(DateTime.Today);
        var resolvedFromDate = fromDate ?? new DateOnly(resolvedAsOfDate.Year, 1, 1);

        var trialBalance = await _reports.GetTrialBalanceAsync(
            resolvedAsOfDate,
            includeZeroBalances: true,
            includeInactiveAccounts: false,
            cancellationToken);
        var balanceSheet = await _reports.GetBalanceSheetAsync(
            resolvedAsOfDate,
            includeZeroBalances: true,
            includeInactiveAccounts: false,
            cancellationToken);
        var profitAndLoss = await _reports.GetProfitAndLossAsync(
            resolvedFromDate,
            resolvedAsOfDate,
            includeZeroBalances: true,
            includeInactiveAccounts: false,
            cancellationToken);
        var receivables = await _reports.GetAccountsReceivableAgingAsync(
            resolvedAsOfDate,
            includeZeroBalances: false,
            includeInactiveCustomers: false,
            cancellationToken);
        var payables = await _reports.GetAccountsPayableAgingAsync(
            resolvedAsOfDate,
            includeZeroBalances: false,
            includeInactiveVendors: false,
            cancellationToken);

        var cashBalance = trialBalance.Items
            .Where(row => row.AccountType == AccountType.Bank)
            .Sum(row => row.ClosingDebit - row.ClosingCredit);

        var currentIncoming = receivables.Current;
        var overdueIncoming = receivables.Days1To30 + receivables.Days31To60 + receivables.Days61To90 + receivables.Over90;
        var currentOutgoing = payables.Current;
        var overdueOutgoing = payables.Days1To30 + payables.Days31To60 + payables.Days61To90 + payables.Over90;
        var netCashAfterOpenItems = cashBalance + receivables.Total - payables.Total;
        var openInvoiceCount = receivables.Items.Sum(row => row.OpenInvoiceCount);
        var openBillCount = payables.Items.Sum(row => row.OpenBillCount);

        var incomingBuckets = new[]
        {
            new CashFlowBucketDto("Current", receivables.Current),
            new CashFlowBucketDto("1-30", receivables.Days1To30),
            new CashFlowBucketDto("31-60", receivables.Days31To60),
            new CashFlowBucketDto("61-90", receivables.Days61To90),
            new CashFlowBucketDto("90+", receivables.Over90)
        };

        var outgoingBuckets = new[]
        {
            new CashFlowBucketDto("Current", payables.Current),
            new CashFlowBucketDto("1-30", payables.Days1To30),
            new CashFlowBucketDto("31-60", payables.Days31To60),
            new CashFlowBucketDto("61-90", payables.Days61To90),
            new CashFlowBucketDto("90+", payables.Over90)
        };

        var forecastPoints = new[]
        {
            new CashFlowForecastPointDto("Now", cashBalance),
            new CashFlowForecastPointDto("Current", cashBalance + currentIncoming - currentOutgoing),
            new CashFlowForecastPointDto("30d", cashBalance + currentIncoming + receivables.Days1To30 - currentOutgoing - payables.Days1To30),
            new CashFlowForecastPointDto("60d", cashBalance + currentIncoming + receivables.Days1To30 + receivables.Days31To60 - currentOutgoing - payables.Days1To30 - payables.Days31To60),
            new CashFlowForecastPointDto("90d+", netCashAfterOpenItems)
        };

        return Ok(new CashFlowHubReportDto(
            resolvedAsOfDate,
            resolvedFromDate,
            resolvedAsOfDate,
            ResolveCurrency(receivables, payables),
            cashBalance,
            balanceSheet.TotalAssets,
            balanceSheet.TotalLiabilities,
            balanceSheet.TotalEquity,
            receivables.Total,
            overdueIncoming,
            payables.Total,
            overdueOutgoing,
            netCashAfterOpenItems,
            profitAndLoss.TotalIncome,
            profitAndLoss.TotalExpenses + profitAndLoss.TotalCostOfGoodsSold,
            profitAndLoss.NetProfit,
            openInvoiceCount,
            openBillCount,
            incomingBuckets,
            outgoingBuckets,
            forecastPoints,
            BuildAlerts(cashBalance, netCashAfterOpenItems, overdueIncoming, overdueOutgoing, openInvoiceCount, openBillCount)));
    }

    private static string ResolveCurrency(dynamic receivables, dynamic payables)
    {
        var arCurrency = receivables.Items.Count == 0 ? string.Empty : receivables.Items[0].Currency;
        if (!string.IsNullOrWhiteSpace(arCurrency))
        {
            return arCurrency;
        }

        var apCurrency = payables.Items.Count == 0 ? string.Empty : payables.Items[0].Currency;
        return string.IsNullOrWhiteSpace(apCurrency) ? "EGP" : apCurrency;
    }

    private static IReadOnlyList<CashFlowAlertDto> BuildAlerts(
        decimal cashBalance,
        decimal netCashAfterOpenItems,
        decimal overdueIncoming,
        decimal overdueOutgoing,
        int openInvoiceCount,
        int openBillCount)
    {
        var alerts = new List<CashFlowAlertDto>();

        if (cashBalance < 0)
        {
            alerts.Add(new CashFlowAlertDto(
                "critical",
                "Negative cash position",
                "Bank and cash accounts are below zero. Review deposits, checks, and bank transactions."));
        }

        if (netCashAfterOpenItems < 0)
        {
            alerts.Add(new CashFlowAlertDto(
                "warning",
                "Projected cash pressure",
                "Open receivables minus open payables leaves a negative projected cash position."));
        }

        if (overdueIncoming > 0)
        {
            alerts.Add(new CashFlowAlertDto(
                "info",
                "Overdue customer balances",
                $"{openInvoiceCount} open invoice(s) include overdue receivables that can improve cash once collected."));
        }

        if (overdueOutgoing > 0)
        {
            alerts.Add(new CashFlowAlertDto(
                "info",
                "Vendor bills need attention",
                $"{openBillCount} open bill(s) include overdue payables. Prioritize payment planning."));
        }

        if (alerts.Count == 0)
        {
            alerts.Add(new CashFlowAlertDto(
                "success",
                "Cash flow looks stable",
                "No overdue cash-flow pressure was detected from current receivables and payables reports."));
        }

        return alerts;
    }
}
