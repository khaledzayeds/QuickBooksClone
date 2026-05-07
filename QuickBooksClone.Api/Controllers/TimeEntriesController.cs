using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Api.Contracts.TimeTracking;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.TimeTracking;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/time-entries")]
[RequirePermission("TimeTracking.Manage")]
public sealed class TimeEntriesController : ControllerBase
{
    private readonly QuickBooksCloneDbContext _db;

    public TimeEntriesController(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    [ProducesResponseType(typeof(TimeEntryListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<TimeEntryListResponse>> Search(
        [FromQuery] DateOnly? fromDate,
        [FromQuery] DateOnly? toDate,
        [FromQuery] string? search,
        [FromQuery] TimeEntryStatus? status,
        [FromQuery] bool? isBillable,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 200);

        var query = _db.Set<TimeEntry>().AsNoTracking();

        if (fromDate is not null)
        {
            query = query.Where(entry => entry.WorkDate >= fromDate);
        }

        if (toDate is not null)
        {
            query = query.Where(entry => entry.WorkDate <= toDate);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            query = query.Where(entry => entry.PersonName.Contains(term) || entry.Activity.Contains(term));
        }

        if (status is not null)
        {
            query = query.Where(entry => entry.Status == status);
        }

        if (isBillable is not null)
        {
            query = query.Where(entry => entry.IsBillable == isBillable);
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var totalHours = await query.SumAsync(entry => (decimal?)entry.Hours, cancellationToken) ?? 0;
        var billableHours = await query.Where(entry => entry.IsBillable).SumAsync(entry => (decimal?)entry.Hours, cancellationToken) ?? 0;
        var nonBillableHours = totalHours - billableHours;

        var entries = await query
            .OrderByDescending(entry => entry.WorkDate)
            .ThenBy(entry => entry.PersonName)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return Ok(new TimeEntryListResponse(
            await ToDtosAsync(entries, cancellationToken),
            totalCount,
            page,
            pageSize,
            totalHours,
            billableHours,
            nonBillableHours));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TimeEntryDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var entry = await _db.Set<TimeEntry>().AsNoTracking().SingleOrDefaultAsync(current => current.Id == id, cancellationToken);
        if (entry is null)
        {
            return NotFound();
        }

        return Ok((await ToDtosAsync([entry], cancellationToken)).Single());
    }

    [HttpPost]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<TimeEntryDto>> Create(CreateTimeEntryRequest request, CancellationToken cancellationToken = default)
    {
        if (request.CustomerId is not null && !await _db.Customers.AnyAsync(customer => customer.Id == request.CustomerId, cancellationToken))
        {
            return BadRequest("Customer does not exist.");
        }

        if (request.ServiceItemId is not null && !await _db.Items.AnyAsync(item => item.Id == request.ServiceItemId, cancellationToken))
        {
            return BadRequest("Service item does not exist.");
        }

        try
        {
            var entry = new TimeEntry(
                request.WorkDate,
                request.PersonName,
                request.Hours,
                request.Activity,
                request.Notes,
                request.CustomerId,
                request.ServiceItemId,
                request.IsBillable);

            _db.Set<TimeEntry>().Add(entry);
            await _db.SaveChangesAsync(cancellationToken);

            return CreatedAtAction(nameof(Get), new { id = entry.Id }, (await ToDtosAsync([entry], cancellationToken)).Single());
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
        catch (ArgumentOutOfRangeException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TimeEntryDto>> Update(Guid id, UpdateTimeEntryRequest request, CancellationToken cancellationToken = default)
    {
        var entry = await _db.Set<TimeEntry>().SingleOrDefaultAsync(current => current.Id == id, cancellationToken);
        if (entry is null)
        {
            return NotFound();
        }

        if (request.CustomerId is not null && !await _db.Customers.AnyAsync(customer => customer.Id == request.CustomerId, cancellationToken))
        {
            return BadRequest("Customer does not exist.");
        }

        if (request.ServiceItemId is not null && !await _db.Items.AnyAsync(item => item.Id == request.ServiceItemId, cancellationToken))
        {
            return BadRequest("Service item does not exist.");
        }

        try
        {
            entry.Update(
                request.WorkDate,
                request.PersonName,
                request.Hours,
                request.Activity,
                request.Notes,
                request.CustomerId,
                request.ServiceItemId,
                request.IsBillable);
            await _db.SaveChangesAsync(cancellationToken);
            return Ok((await ToDtosAsync([entry], cancellationToken)).Single());
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
        catch (ArgumentOutOfRangeException exception)
        {
            return BadRequest(exception.Message);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPost("{id:guid}/approve")]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TimeEntryDto>> Approve(Guid id, CancellationToken cancellationToken = default)
    {
        var entry = await _db.Set<TimeEntry>().SingleOrDefaultAsync(current => current.Id == id, cancellationToken);
        if (entry is null)
        {
            return NotFound();
        }

        try
        {
            entry.Approve();
            await _db.SaveChangesAsync(cancellationToken);
            return Ok((await ToDtosAsync([entry], cancellationToken)).Single());
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPost("{id:guid}/mark-invoiced")]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TimeEntryDto>> MarkInvoiced(Guid id, CancellationToken cancellationToken = default)
    {
        var entry = await _db.Set<TimeEntry>().SingleOrDefaultAsync(current => current.Id == id, cancellationToken);
        if (entry is null)
        {
            return NotFound();
        }

        try
        {
            entry.MarkInvoiced();
            await _db.SaveChangesAsync(cancellationToken);
            return Ok((await ToDtosAsync([entry], cancellationToken)).Single());
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPatch("{id:guid}/void")]
    [ProducesResponseType(typeof(TimeEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TimeEntryDto>> Void(Guid id, CancellationToken cancellationToken = default)
    {
        var entry = await _db.Set<TimeEntry>().SingleOrDefaultAsync(current => current.Id == id, cancellationToken);
        if (entry is null)
        {
            return NotFound();
        }

        try
        {
            entry.Void();
            await _db.SaveChangesAsync(cancellationToken);
            return Ok((await ToDtosAsync([entry], cancellationToken)).Single());
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    private async Task<IReadOnlyList<TimeEntryDto>> ToDtosAsync(IReadOnlyList<TimeEntry> entries, CancellationToken cancellationToken)
    {
        var customerIds = entries.Where(entry => entry.CustomerId is not null).Select(entry => entry.CustomerId!.Value).Distinct().ToList();
        var itemIds = entries.Where(entry => entry.ServiceItemId is not null).Select(entry => entry.ServiceItemId!.Value).Distinct().ToList();

        var customers = await _db.Customers
            .AsNoTracking()
            .Where(customer => customerIds.Contains(customer.Id))
            .ToDictionaryAsync(customer => customer.Id, customer => customer.DisplayName, cancellationToken);

        var items = await _db.Items
            .AsNoTracking()
            .Where(item => itemIds.Contains(item.Id))
            .ToDictionaryAsync(item => item.Id, item => item.Name, cancellationToken);

        return entries.Select(entry => new TimeEntryDto(
            entry.Id,
            entry.WorkDate,
            entry.PersonName,
            entry.Hours,
            entry.Activity,
            entry.Notes,
            entry.CustomerId,
            entry.CustomerId is not null && customers.TryGetValue(entry.CustomerId.Value, out var customerName) ? customerName : null,
            entry.ServiceItemId,
            entry.ServiceItemId is not null && items.TryGetValue(entry.ServiceItemId.Value, out var itemName) ? itemName : null,
            entry.IsBillable,
            entry.Status,
            entry.CreatedAt,
            entry.UpdatedAt)).ToList();
    }
}
