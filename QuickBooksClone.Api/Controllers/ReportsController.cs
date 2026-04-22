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
}
