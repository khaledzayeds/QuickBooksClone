using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Zayed.Api.Contracts.TimeTracking;
using Zayed.Api.Security;
using Zayed.Core.Items;
using Zayed.Infrastructure.Persistence;

namespace Zayed.Api.Controllers;

[ApiController]
[Route("api/time-entries/lookups")]
[RequirePermission("TimeTracking.Manage")]
public sealed class TimeEntryLookupsController : ControllerBase
{
    private readonly ZayedDbContext _db;

    public TimeEntryLookupsController(ZayedDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    [ProducesResponseType(typeof(TimeEntryLookupsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<TimeEntryLookupsDto>> Get(CancellationToken cancellationToken = default)
    {
        var customers = await _db.Customers
            .AsNoTracking()
            .Where(customer => customer.IsActive)
            .OrderBy(customer => customer.DisplayName)
            .Select(customer => new TimeEntryCustomerLookupDto(customer.Id, customer.DisplayName))
            .ToListAsync(cancellationToken);

        var serviceItems = await _db.Items
            .AsNoTracking()
            .Where(item => item.IsActive && item.ItemType == ItemType.Service)
            .OrderBy(item => item.Name)
            .Select(item => new TimeEntryServiceItemLookupDto(item.Id, item.Name))
            .ToListAsync(cancellationToken);

        return Ok(new TimeEntryLookupsDto(customers, serviceItems));
    }
}
