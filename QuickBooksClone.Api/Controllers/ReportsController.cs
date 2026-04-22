using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Reports;
using QuickBooksClone.Core.Reports;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/reports")]
public sealed class ReportsController : ControllerBase
{
    private readonly IFinancialReportService _reports;

    public ReportsController(IFinancialReportService reports)
    {
        _reports = reports;
    }

    [HttpGet("trial-balance")]
    [ProducesResponseType(typeof(TrialBalanceReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<TrialBalanceReportDto>> GetTrialBalance(
        [FromQuery] DateOnly? asOfDate,
        [FromQuery] bool includeZeroBalances = false,
        [FromQuery] bool includeInactiveAccounts = false,
        CancellationToken cancellationToken = default)
    {
        var report = await _reports.GetTrialBalanceAsync(
            asOfDate ?? DateOnly.FromDateTime(DateTime.Today),
            includeZeroBalances,
            includeInactiveAccounts,
            cancellationToken);

        return Ok(new TrialBalanceReportDto(
            report.AsOfDate,
            report.Items
                .Select(row => new TrialBalanceRowDto(
                    row.AccountId,
                    row.AccountCode,
                    row.AccountName,
                    row.AccountType,
                    row.TotalDebit,
                    row.TotalCredit,
                    row.ClosingDebit,
                    row.ClosingCredit))
                .ToList(),
            report.TotalDebit,
            report.TotalCredit));
    }

    [HttpGet("balance-sheet")]
    [ProducesResponseType(typeof(BalanceSheetReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<BalanceSheetReportDto>> GetBalanceSheet(
        [FromQuery] DateOnly? asOfDate,
        [FromQuery] bool includeZeroBalances = false,
        [FromQuery] bool includeInactiveAccounts = false,
        CancellationToken cancellationToken = default)
    {
        var report = await _reports.GetBalanceSheetAsync(
            asOfDate ?? DateOnly.FromDateTime(DateTime.Today),
            includeZeroBalances,
            includeInactiveAccounts,
            cancellationToken);

        return Ok(new BalanceSheetReportDto(
            report.AsOfDate,
            report.Sections
                .Select(section => new BalanceSheetSectionDto(
                    section.Key,
                    section.Title,
                    section.Items
                        .Select(item => new BalanceSheetRowDto(
                            item.AccountId,
                            item.AccountCode,
                            item.AccountName,
                            item.AccountType,
                            item.Amount))
                        .ToList(),
                    section.Total))
                .ToList(),
            report.TotalAssets,
            report.TotalLiabilities,
            report.TotalEquity,
            report.TotalLiabilitiesAndEquity));
    }

    [HttpGet("profit-and-loss")]
    [ProducesResponseType(typeof(ProfitAndLossReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ProfitAndLossReportDto>> GetProfitAndLoss(
        [FromQuery] DateOnly? fromDate,
        [FromQuery] DateOnly? toDate,
        [FromQuery] bool includeZeroBalances = false,
        [FromQuery] bool includeInactiveAccounts = false,
        CancellationToken cancellationToken = default)
    {
        var resolvedToDate = toDate ?? DateOnly.FromDateTime(DateTime.Today);
        var resolvedFromDate = fromDate ?? new DateOnly(resolvedToDate.Year, 1, 1);

        var report = await _reports.GetProfitAndLossAsync(
            resolvedFromDate,
            resolvedToDate,
            includeZeroBalances,
            includeInactiveAccounts,
            cancellationToken);

        return Ok(new ProfitAndLossReportDto(
            report.FromDate,
            report.ToDate,
            report.Sections
                .Select(section => new ProfitAndLossSectionDto(
                    section.Key,
                    section.Title,
                    section.Items
                        .Select(item => new ProfitAndLossRowDto(
                            item.AccountId,
                            item.AccountCode,
                            item.AccountName,
                            item.AccountType,
                            item.Amount))
                        .ToList(),
                    section.Total))
                .ToList(),
            report.TotalIncome,
            report.TotalCostOfGoodsSold,
            report.GrossProfit,
            report.TotalExpenses,
            report.NetProfit));
    }
}
