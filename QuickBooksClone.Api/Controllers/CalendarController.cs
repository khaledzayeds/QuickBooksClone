using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Contracts.Calendar;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/calendar")]
[RequirePermission("Reports.View")]
public sealed class CalendarController : ControllerBase
{
    private readonly QuickBooksCloneDbContext _db;

    public CalendarController(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    [ProducesResponseType(typeof(CalendarSummaryDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<CalendarSummaryDto>> GetCalendar(
        [FromQuery] DateOnly? fromDate,
        [FromQuery] DateOnly? toDate,
        CancellationToken cancellationToken = default)
    {
        var today = DateOnly.FromDateTime(DateTime.Today);
        var resolvedFromDate = fromDate ?? today.AddDays(-30);
        var resolvedToDate = toDate ?? today.AddDays(60);

        if (resolvedToDate < resolvedFromDate)
        {
            return BadRequest("To date cannot be before from date.");
        }

        var invoices = await _db.Invoices
            .AsNoTracking()
            .Include(invoice => invoice.Lines)
            .Where(invoice => invoice.DueDate >= resolvedFromDate && invoice.DueDate <= resolvedToDate)
            .Where(invoice => invoice.Status != InvoiceStatus.Draft && invoice.Status != InvoiceStatus.Paid && invoice.Status != InvoiceStatus.Void && invoice.Status != InvoiceStatus.Returned)
            .ToListAsync(cancellationToken);

        var customerIds = invoices.Select(invoice => invoice.CustomerId).Distinct().ToList();
        var customers = await _db.Customers
            .AsNoTracking()
            .Where(customer => customerIds.Contains(customer.Id))
            .ToDictionaryAsync(customer => customer.Id, customer => customer.DisplayName, cancellationToken);

        var invoiceEvents = invoices
            .Where(invoice => invoice.BalanceDue > 0)
            .Select(invoice => new CalendarEventDto(
                invoice.Id,
                "invoice",
                invoice.Id,
                invoice.InvoiceNumber,
                $"Invoice due: {invoice.InvoiceNumber}",
                customers.TryGetValue(invoice.CustomerId, out var customerName) ? customerName : "Unknown customer",
                invoice.InvoiceDate,
                invoice.DueDate,
                invoice.BalanceDue,
                invoice.Status.ToString(),
                ResolveSeverity(invoice.DueDate, today),
                $"/sales/invoices/{invoice.Id}"))
            .ToList();

        var bills = await _db.PurchaseBills
            .AsNoTracking()
            .Include(bill => bill.Lines)
            .Where(bill => bill.DueDate >= resolvedFromDate && bill.DueDate <= resolvedToDate)
            .Where(bill => bill.Status != PurchaseBillStatus.Draft && bill.Status != PurchaseBillStatus.Paid && bill.Status != PurchaseBillStatus.Void && bill.Status != PurchaseBillStatus.Returned)
            .ToListAsync(cancellationToken);

        var vendorIds = bills.Select(bill => bill.VendorId).Distinct().ToList();
        var vendors = await _db.Vendors
            .AsNoTracking()
            .Where(vendor => vendorIds.Contains(vendor.Id))
            .ToDictionaryAsync(vendor => vendor.Id, vendor => vendor.DisplayName, cancellationToken);

        var billEvents = bills
            .Where(bill => bill.BalanceDue > 0)
            .Select(bill => new CalendarEventDto(
                bill.Id,
                "bill",
                bill.Id,
                bill.BillNumber,
                $"Bill due: {bill.BillNumber}",
                vendors.TryGetValue(bill.VendorId, out var vendorName) ? vendorName : "Unknown vendor",
                bill.BillDate,
                bill.DueDate,
                bill.BalanceDue,
                bill.Status.ToString(),
                ResolveSeverity(bill.DueDate, today),
                $"/purchases/bills/{bill.Id}"))
            .ToList();

        var events = invoiceEvents
            .Concat(billEvents)
            .OrderBy(calendarEvent => calendarEvent.DueDate)
            .ThenBy(calendarEvent => calendarEvent.SourceType)
            .ThenBy(calendarEvent => calendarEvent.DocumentNumber)
            .ToList();

        return Ok(new CalendarSummaryDto(
            resolvedFromDate,
            resolvedToDate,
            today,
            events.Count,
            events.Count(calendarEvent => calendarEvent.DueDate < today),
            events.Count(calendarEvent => calendarEvent.DueDate == today),
            events.Count(calendarEvent => calendarEvent.DueDate > today),
            invoiceEvents.Sum(calendarEvent => calendarEvent.AmountDue),
            billEvents.Sum(calendarEvent => calendarEvent.AmountDue),
            events));
    }

    private static string ResolveSeverity(DateOnly dueDate, DateOnly today)
    {
        if (dueDate < today) return "overdue";
        if (dueDate == today) return "dueToday";
        if (dueDate <= today.AddDays(7)) return "soon";
        return "upcoming";
    }
}
