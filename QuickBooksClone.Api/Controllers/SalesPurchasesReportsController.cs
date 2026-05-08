using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Contracts.Reports;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/reports")]
[RequirePermission("Reports.View")]
public sealed class SalesPurchasesReportsController : ControllerBase
{
    private readonly QuickBooksCloneDbContext _db;

    public SalesPurchasesReportsController(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    [HttpGet("sales-summary")]
    [ProducesResponseType(typeof(SalesSummaryReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<SalesSummaryReportDto>> SalesSummary([FromQuery] DateOnly? fromDate, [FromQuery] DateOnly? toDate, CancellationToken cancellationToken = default)
    {
        var rows = await QueryAsync(
            """
            SELECT i.Id,
                   i.InvoiceNumber,
                   i.InvoiceDate,
                   i.DueDate,
                   i.CustomerId,
                   COALESCE(c.DisplayName, 'Unknown customer') CustomerName,
                   i.Status,
                   COALESCE(SUM((l.Quantity * l.UnitPrice) - ((l.Quantity * l.UnitPrice) * l.DiscountPercent / 100)), 0) Subtotal,
                   i.TaxAmount,
                   i.PaidAmount,
                   i.CreditAppliedAmount,
                   i.ReturnedAmount
            FROM invoices i
            LEFT JOIN customers c ON c.Id = i.CustomerId
            LEFT JOIN invoice_lines l ON l.InvoiceId = i.Id
            WHERE (@FromDate IS NULL OR i.InvoiceDate >= @FromDate)
              AND (@ToDate IS NULL OR i.InvoiceDate <= @ToDate)
            GROUP BY i.Id, i.InvoiceNumber, i.InvoiceDate, i.DueDate, i.CustomerId, c.DisplayName, i.Status, i.TaxAmount, i.PaidAmount, i.CreditAppliedAmount, i.ReturnedAmount
            ORDER BY i.InvoiceDate DESC, i.InvoiceNumber DESC
            """,
            DateParameters(fromDate, toDate),
            reader => new SalesReportRow(
                reader.GetGuid(0),
                reader.GetString(1),
                DateOnly.FromDateTime(reader.GetDateTime(2)),
                DateOnly.FromDateTime(reader.GetDateTime(3)),
                reader.GetGuid(4),
                reader.GetString(5),
                reader.GetInt32(6),
                reader.GetDecimal(7),
                reader.GetDecimal(8),
                reader.GetDecimal(9),
                reader.GetDecimal(10),
                reader.GetDecimal(11)),
            cancellationToken);

        var invoices = rows
            .Select(row => new SalesSummaryInvoiceDto(
                row.Id,
                row.InvoiceNumber,
                row.InvoiceDate,
                row.DueDate,
                row.CustomerName,
                row.Status,
                row.TotalAmount,
                row.AppliedAmount,
                row.BalanceDue))
            .ToList();

        var byStatus = rows
            .GroupBy(row => row.Status)
            .OrderBy(group => group.Key)
            .Select(group => new SalesSummaryByStatusDto(
                group.Key,
                group.Count(),
                group.Sum(row => row.TotalAmount),
                group.Sum(row => row.AppliedAmount),
                group.Sum(row => row.BalanceDue)))
            .ToList();

        var byCustomer = rows
            .GroupBy(row => new { row.CustomerId, row.CustomerName })
            .OrderBy(group => group.Key.CustomerName)
            .Select(group => new SalesSummaryByCustomerDto(
                group.Key.CustomerId,
                group.Key.CustomerName,
                group.Count(),
                group.Sum(row => row.TotalAmount),
                group.Sum(row => row.AppliedAmount),
                group.Sum(row => row.BalanceDue)))
            .ToList();

        return Ok(new SalesSummaryReportDto(
            fromDate,
            toDate,
            rows.Count,
            byCustomer.Count,
            rows.Sum(row => row.Subtotal),
            rows.Sum(row => row.TaxAmount),
            rows.Sum(row => row.TotalAmount),
            rows.Sum(row => row.AppliedAmount),
            rows.Sum(row => row.BalanceDue),
            byStatus,
            byCustomer,
            invoices));
    }

    [HttpGet("purchases-summary")]
    [ProducesResponseType(typeof(PurchasesSummaryReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<PurchasesSummaryReportDto>> PurchasesSummary([FromQuery] DateOnly? fromDate, [FromQuery] DateOnly? toDate, CancellationToken cancellationToken = default)
    {
        var rows = await QueryAsync(
            """
            SELECT b.Id,
                   b.BillNumber,
                   b.BillDate,
                   b.DueDate,
                   b.VendorId,
                   COALESCE(v.DisplayName, 'Unknown vendor') VendorName,
                   b.Status,
                   COALESCE(SUM(l.Quantity * l.UnitCost), 0) Subtotal,
                   b.TaxAmount,
                   b.PaidAmount,
                   b.CreditAppliedAmount,
                   b.ReturnedAmount
            FROM purchase_bills b
            LEFT JOIN vendors v ON v.Id = b.VendorId
            LEFT JOIN purchase_bill_lines l ON l.PurchaseBillId = b.Id
            WHERE (@FromDate IS NULL OR b.BillDate >= @FromDate)
              AND (@ToDate IS NULL OR b.BillDate <= @ToDate)
            GROUP BY b.Id, b.BillNumber, b.BillDate, b.DueDate, b.VendorId, v.DisplayName, b.Status, b.TaxAmount, b.PaidAmount, b.CreditAppliedAmount, b.ReturnedAmount
            ORDER BY b.BillDate DESC, b.BillNumber DESC
            """,
            DateParameters(fromDate, toDate),
            reader => new PurchasesReportRow(
                reader.GetGuid(0),
                reader.GetString(1),
                DateOnly.FromDateTime(reader.GetDateTime(2)),
                DateOnly.FromDateTime(reader.GetDateTime(3)),
                reader.GetGuid(4),
                reader.GetString(5),
                reader.GetInt32(6),
                reader.GetDecimal(7),
                reader.GetDecimal(8),
                reader.GetDecimal(9),
                reader.GetDecimal(10),
                reader.GetDecimal(11)),
            cancellationToken);

        var bills = rows
            .Select(row => new PurchasesSummaryBillDto(
                row.Id,
                row.BillNumber,
                row.BillDate,
                row.DueDate,
                row.VendorName,
                row.Status,
                row.TotalAmount,
                row.AppliedAmount,
                row.BalanceDue))
            .ToList();

        var byStatus = rows
            .GroupBy(row => row.Status)
            .OrderBy(group => group.Key)
            .Select(group => new PurchasesSummaryByStatusDto(
                group.Key,
                group.Count(),
                group.Sum(row => row.TotalAmount),
                group.Sum(row => row.AppliedAmount),
                group.Sum(row => row.BalanceDue)))
            .ToList();

        var byVendor = rows
            .GroupBy(row => new { row.VendorId, row.VendorName })
            .OrderBy(group => group.Key.VendorName)
            .Select(group => new PurchasesSummaryByVendorDto(
                group.Key.VendorId,
                group.Key.VendorName,
                group.Count(),
                group.Sum(row => row.TotalAmount),
                group.Sum(row => row.AppliedAmount),
                group.Sum(row => row.BalanceDue)))
            .ToList();

        return Ok(new PurchasesSummaryReportDto(
            fromDate,
            toDate,
            rows.Count,
            byVendor.Count,
            rows.Sum(row => row.Subtotal),
            rows.Sum(row => row.TaxAmount),
            rows.Sum(row => row.TotalAmount),
            rows.Sum(row => row.AppliedAmount),
            rows.Sum(row => row.BalanceDue),
            byStatus,
            byVendor,
            bills));
    }

    private static Dictionary<string, object?> DateParameters(DateOnly? fromDate, DateOnly? toDate) => new()
    {
        ["FromDate"] = fromDate?.ToDateTime(TimeOnly.MinValue),
        ["ToDate"] = toDate?.ToDateTime(TimeOnly.MinValue),
    };

    private async Task<IReadOnlyList<T>> QueryAsync<T>(string sql, IReadOnlyDictionary<string, object?> parameters, Func<IDataRecord, T> mapper, CancellationToken cancellationToken)
    {
        var result = new List<T>();
        await using var command = _db.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        AddParameters(command, parameters);
        if (command.Connection!.State != ConnectionState.Open) await command.Connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) result.Add(mapper(reader));
        return result;
    }

    private static void AddParameters(IDbCommand command, IReadOnlyDictionary<string, object?> parameters)
    {
        foreach (var (name, value) in parameters)
        {
            var parameter = command.CreateParameter();
            parameter.ParameterName = $"@{name}";
            parameter.Value = value ?? DBNull.Value;
            command.Parameters.Add(parameter);
        }
    }

    private sealed record SalesReportRow(
        Guid Id,
        string InvoiceNumber,
        DateOnly InvoiceDate,
        DateOnly DueDate,
        Guid CustomerId,
        string CustomerName,
        int Status,
        decimal Subtotal,
        decimal TaxAmount,
        decimal PaidAmount,
        decimal CreditAppliedAmount,
        decimal ReturnedAmount)
    {
        public decimal TotalAmount => Subtotal + TaxAmount;
        public decimal AppliedAmount => PaidAmount + CreditAppliedAmount + ReturnedAmount;
        public decimal BalanceDue => Math.Max(0, TotalAmount - AppliedAmount);
    }

    private sealed record PurchasesReportRow(
        Guid Id,
        string BillNumber,
        DateOnly BillDate,
        DateOnly DueDate,
        Guid VendorId,
        string VendorName,
        int Status,
        decimal Subtotal,
        decimal TaxAmount,
        decimal PaidAmount,
        decimal CreditAppliedAmount,
        decimal ReturnedAmount)
    {
        public decimal TotalAmount => Subtotal + TaxAmount;
        public decimal AppliedAmount => PaidAmount + CreditAppliedAmount + ReturnedAmount;
        public decimal BalanceDue => Math.Max(0, TotalAmount - AppliedAmount);
    }
}
