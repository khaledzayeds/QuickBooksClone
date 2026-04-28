using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Contracts.Reports;
using QuickBooksClone.Core.Reports;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/reports")]
[RequirePermission("Reports.View")]
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

    [HttpGet("accounts-receivable-aging")]
    [ProducesResponseType(typeof(AccountsReceivableAgingReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<AccountsReceivableAgingReportDto>> GetAccountsReceivableAging(
        [FromQuery] DateOnly? asOfDate,
        [FromQuery] bool includeZeroBalances = false,
        [FromQuery] bool includeInactiveCustomers = false,
        CancellationToken cancellationToken = default)
    {
        var report = await _reports.GetAccountsReceivableAgingAsync(
            asOfDate ?? DateOnly.FromDateTime(DateTime.Today),
            includeZeroBalances,
            includeInactiveCustomers,
            cancellationToken);

        return Ok(new AccountsReceivableAgingReportDto(
            report.AsOfDate,
            report.Items
                .Select(row => new AccountsReceivableAgingRowDto(
                    row.CustomerId,
                    row.CustomerName,
                    row.Currency,
                    row.Current,
                    row.Days1To30,
                    row.Days31To60,
                    row.Days61To90,
                    row.Over90,
                    row.Total,
                    row.CreditBalance,
                    row.OpenInvoiceCount))
                .ToList(),
            report.Current,
            report.Days1To30,
            report.Days31To60,
            report.Days61To90,
            report.Over90,
            report.Total));
    }

    [HttpGet("accounts-payable-aging")]
    [ProducesResponseType(typeof(AccountsPayableAgingReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<AccountsPayableAgingReportDto>> GetAccountsPayableAging(
        [FromQuery] DateOnly? asOfDate,
        [FromQuery] bool includeZeroBalances = false,
        [FromQuery] bool includeInactiveVendors = false,
        CancellationToken cancellationToken = default)
    {
        var report = await _reports.GetAccountsPayableAgingAsync(
            asOfDate ?? DateOnly.FromDateTime(DateTime.Today),
            includeZeroBalances,
            includeInactiveVendors,
            cancellationToken);

        return Ok(new AccountsPayableAgingReportDto(
            report.AsOfDate,
            report.Items
                .Select(row => new AccountsPayableAgingRowDto(
                    row.VendorId,
                    row.VendorName,
                    row.Currency,
                    row.Current,
                    row.Days1To30,
                    row.Days31To60,
                    row.Days61To90,
                    row.Over90,
                    row.Total,
                    row.CreditBalance,
                    row.OpenBillCount))
                .ToList(),
            report.Current,
            report.Days1To30,
            report.Days31To60,
            report.Days61To90,
            report.Over90,
            report.Total));
    }

    [HttpGet("inventory-valuation")]
    [ProducesResponseType(typeof(InventoryValuationReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<InventoryValuationReportDto>> GetInventoryValuation(
        [FromQuery] DateOnly? fromDate,
        [FromQuery] DateOnly? toDate,
        [FromQuery] bool includeZeroBalances = false,
        [FromQuery] bool includeInactiveItems = false,
        CancellationToken cancellationToken = default)
    {
        var resolvedToDate = toDate ?? DateOnly.FromDateTime(DateTime.Today);
        var resolvedFromDate = fromDate ?? new DateOnly(resolvedToDate.Year, 1, 1);

        var report = await _reports.GetInventoryValuationAsync(
            resolvedFromDate,
            resolvedToDate,
            includeZeroBalances,
            includeInactiveItems,
            cancellationToken);

        return Ok(new InventoryValuationReportDto(
            report.FromDate,
            report.ToDate,
            report.Items
                .Select(row => new InventoryValuationRowDto(
                    row.ItemId,
                    row.ItemName,
                    row.Sku,
                    row.Unit,
                    row.UnitCost,
                    row.OpeningQuantity,
                    row.QuantityIn,
                    row.QuantityOut,
                    row.ClosingQuantity,
                    row.OpeningValue,
                    row.QuantityInValue,
                    row.QuantityOutValue,
                    row.ClosingValue))
                .ToList(),
            report.TotalOpeningQuantity,
            report.TotalQuantityIn,
            report.TotalQuantityOut,
            report.TotalClosingQuantity,
            report.TotalOpeningValue,
            report.TotalQuantityInValue,
            report.TotalQuantityOutValue,
            report.TotalClosingValue));
    }
}
