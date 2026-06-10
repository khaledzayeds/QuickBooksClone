using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Zayed.Api.Contracts.Hotels;
using Zayed.Core.Companies;
using Zayed.Core.Hotels;
using Zayed.Core.Modules;
using Zayed.Infrastructure.Modules;
using Zayed.Infrastructure.Persistence;

namespace Zayed.Api.Controllers;

[ApiController]
[Route("api/hotels/master-data")]
public sealed class HotelMasterDataController : ControllerBase
{
    private readonly ZayedDbContext _db;
    private readonly ICompanyRuntimeService _runtime;
    private readonly ICompanyModuleAccessService _modules;

    public HotelMasterDataController(
        ZayedDbContext db,
        ICompanyRuntimeService runtime,
        ICompanyModuleAccessService modules)
    {
        _db = db;
        _runtime = runtime;
        _modules = modules;
    }

    [HttpGet("properties")]
    public async Task<ActionResult<IReadOnlyList<HotelPropertyDto>>> GetProperties([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.Hotels, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var items = await _db.HotelProperties
            .Where(item => item.CompanyId == companyId && (includeInactive || item.IsActive))
            .OrderBy(item => item.Name)
            .Select(item => ToDto(item))
            .ToListAsync(cancellationToken);
        return Ok(items);
    }

    [HttpPost("properties")]
    public async Task<ActionResult<HotelPropertyDto>> CreateProperty(UpsertHotelPropertyRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.Hotels, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        if (await _db.HotelProperties.AnyAsync(item => item.CompanyId == companyId && item.Name == request.Name.Trim(), cancellationToken))
        {
            return Conflict("Hotel name already exists.");
        }

        var item = new HotelProperty(request.Name, request.Country ?? "Saudi Arabia", request.City, request.Address, request.Phone, request.Email, companyId);
        _db.HotelProperties.Add(item);
        await _db.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(GetProperties), ToDto(item));
    }

    [HttpPut("properties/{id:guid}")]
    public async Task<ActionResult<HotelPropertyDto>> UpdateProperty(Guid id, UpsertHotelPropertyRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.Hotels, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var item = await _db.HotelProperties.FirstOrDefaultAsync(current => current.Id == id && current.CompanyId == companyId, cancellationToken);
        if (item is null)
        {
            return NotFound();
        }

        if (await _db.HotelProperties.AnyAsync(current => current.CompanyId == companyId && current.Id != id && current.Name == request.Name.Trim(), cancellationToken))
        {
            return Conflict("Hotel name already exists.");
        }

        item.Update(request.Name, request.Country ?? "Saudi Arabia", request.City, request.Address, request.Phone, request.Email);
        await _db.SaveChangesAsync(cancellationToken);
        return Ok(ToDto(item));
    }

    [HttpPatch("properties/{id:guid}/active")]
    public Task<ActionResult<HotelPropertyDto>> SetPropertyActive(Guid id, SetHotelMasterDataActiveRequest request, CancellationToken cancellationToken = default)
        => SetActiveAsync(id, request.IsActive, ModuleCodes.Hotels, _db.HotelProperties, ToDto, cancellationToken);

    [HttpGet("room-types")]
    public async Task<ActionResult<IReadOnlyList<HotelRoomTypeDto>>> GetRoomTypes([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelRoomTypes, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var items = await _db.HotelRoomTypes
            .Where(item => item.CompanyId == companyId && (includeInactive || item.IsActive))
            .OrderBy(item => item.Code)
            .Select(item => ToDto(item))
            .ToListAsync(cancellationToken);
        return Ok(items);
    }

    [HttpPost("room-types")]
    public async Task<ActionResult<HotelRoomTypeDto>> CreateRoomType(UpsertHotelRoomTypeRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelRoomTypes, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var code = request.Code.Trim().ToUpperInvariant();
        if (await _db.HotelRoomTypes.AnyAsync(item => item.CompanyId == companyId && item.Code == code, cancellationToken))
        {
            return Conflict("Room type code already exists.");
        }

        var item = new HotelRoomType(request.Code, request.Name, request.Capacity, request.Description, companyId);
        _db.HotelRoomTypes.Add(item);
        await _db.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(GetRoomTypes), ToDto(item));
    }

    [HttpPut("room-types/{id:guid}")]
    public async Task<ActionResult<HotelRoomTypeDto>> UpdateRoomType(Guid id, UpsertHotelRoomTypeRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelRoomTypes, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var item = await _db.HotelRoomTypes.FirstOrDefaultAsync(current => current.Id == id && current.CompanyId == companyId, cancellationToken);
        if (item is null)
        {
            return NotFound();
        }

        var code = request.Code.Trim().ToUpperInvariant();
        if (await _db.HotelRoomTypes.AnyAsync(current => current.CompanyId == companyId && current.Id != id && current.Code == code, cancellationToken))
        {
            return Conflict("Room type code already exists.");
        }

        item.Update(request.Code, request.Name, request.Capacity, request.Description);
        await _db.SaveChangesAsync(cancellationToken);
        return Ok(ToDto(item));
    }

    [HttpPatch("room-types/{id:guid}/active")]
    public Task<ActionResult<HotelRoomTypeDto>> SetRoomTypeActive(Guid id, SetHotelMasterDataActiveRequest request, CancellationToken cancellationToken = default)
        => SetActiveAsync(id, request.IsActive, ModuleCodes.HotelRoomTypes, _db.HotelRoomTypes, ToDto, cancellationToken);

    [HttpGet("meal-plans")]
    public async Task<ActionResult<IReadOnlyList<HotelMealPlanDto>>> GetMealPlans([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelMealPlans, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var items = await _db.HotelMealPlans
            .Where(item => item.CompanyId == companyId && (includeInactive || item.IsActive))
            .OrderBy(item => item.Code)
            .Select(item => ToDto(item))
            .ToListAsync(cancellationToken);
        return Ok(items);
    }

    [HttpPost("meal-plans")]
    public async Task<ActionResult<HotelMealPlanDto>> CreateMealPlan(UpsertHotelMealPlanRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelMealPlans, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var code = request.Code.Trim().ToUpperInvariant();
        if (await _db.HotelMealPlans.AnyAsync(item => item.CompanyId == companyId && item.Code == code, cancellationToken))
        {
            return Conflict("Meal plan code already exists.");
        }

        var item = new HotelMealPlan(request.Code, request.Name, request.Description, companyId);
        _db.HotelMealPlans.Add(item);
        await _db.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(GetMealPlans), ToDto(item));
    }

    [HttpPut("meal-plans/{id:guid}")]
    public async Task<ActionResult<HotelMealPlanDto>> UpdateMealPlan(Guid id, UpsertHotelMealPlanRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelMealPlans, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var item = await _db.HotelMealPlans.FirstOrDefaultAsync(current => current.Id == id && current.CompanyId == companyId, cancellationToken);
        if (item is null)
        {
            return NotFound();
        }

        var code = request.Code.Trim().ToUpperInvariant();
        if (await _db.HotelMealPlans.AnyAsync(current => current.CompanyId == companyId && current.Id != id && current.Code == code, cancellationToken))
        {
            return Conflict("Meal plan code already exists.");
        }

        item.Update(request.Code, request.Name, request.Description);
        await _db.SaveChangesAsync(cancellationToken);
        return Ok(ToDto(item));
    }

    [HttpPatch("meal-plans/{id:guid}/active")]
    public Task<ActionResult<HotelMealPlanDto>> SetMealPlanActive(Guid id, SetHotelMasterDataActiveRequest request, CancellationToken cancellationToken = default)
        => SetActiveAsync(id, request.IsActive, ModuleCodes.HotelMealPlans, _db.HotelMealPlans, ToDto, cancellationToken);

    [HttpGet("agents")]
    public async Task<ActionResult<IReadOnlyList<HotelAgentDto>>> GetAgents([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelAgents, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var items = await _db.HotelAgents
            .Where(item => item.CompanyId == companyId && (includeInactive || item.IsActive))
            .OrderBy(item => item.Name)
            .Select(item => ToDto(item))
            .ToListAsync(cancellationToken);
        return Ok(items);
    }

    [HttpPost("agents")]
    public async Task<ActionResult<HotelAgentDto>> CreateAgent(UpsertHotelAgentRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelAgents, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        if (await _db.HotelAgents.AnyAsync(item => item.CompanyId == companyId && item.Name == request.Name.Trim(), cancellationToken))
        {
            return Conflict("Agent name already exists.");
        }

        var item = new HotelAgent(request.Name, request.ContactName, request.Email, request.Phone, request.Currency ?? "SAR", companyId);
        _db.HotelAgents.Add(item);
        await _db.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(GetAgents), ToDto(item));
    }

    [HttpPut("agents/{id:guid}")]
    public async Task<ActionResult<HotelAgentDto>> UpdateAgent(Guid id, UpsertHotelAgentRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelAgents, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var item = await _db.HotelAgents.FirstOrDefaultAsync(current => current.Id == id && current.CompanyId == companyId, cancellationToken);
        if (item is null)
        {
            return NotFound();
        }

        if (await _db.HotelAgents.AnyAsync(current => current.CompanyId == companyId && current.Id != id && current.Name == request.Name.Trim(), cancellationToken))
        {
            return Conflict("Agent name already exists.");
        }

        item.Update(request.Name, request.ContactName, request.Email, request.Phone, request.Currency ?? "SAR");
        await _db.SaveChangesAsync(cancellationToken);
        return Ok(ToDto(item));
    }

    [HttpPatch("agents/{id:guid}/active")]
    public Task<ActionResult<HotelAgentDto>> SetAgentActive(Guid id, SetHotelMasterDataActiveRequest request, CancellationToken cancellationToken = default)
        => SetActiveAsync(id, request.IsActive, ModuleCodes.HotelAgents, _db.HotelAgents, ToDto, cancellationToken);

    private async Task<ActionResult?> ValidateModuleAsync(string moduleCode, CancellationToken cancellationToken)
    {
        try
        {
            await _modules.RequireModuleAsync(moduleCode, cancellationToken);
            return null;
        }
        catch (ModuleNotEnabledException exception)
        {
            return StatusCode(StatusCodes.Status403Forbidden, exception.Message);
        }
    }

    private Guid GetCompanyId()
    {
        return _runtime.Current.CompanyId ?? throw new InvalidOperationException("No active company is open.");
    }

    private async Task<ActionResult<TDto>> SetActiveAsync<TEntity, TDto>(
        Guid id,
        bool isActive,
        string moduleCode,
        DbSet<TEntity> set,
        Func<TEntity, TDto> toDto,
        CancellationToken cancellationToken)
        where TEntity : Zayed.Core.Common.EntityBase, Zayed.Core.Common.ITenantEntity
    {
        if (await ValidateModuleAsync(moduleCode, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var item = await set.FirstOrDefaultAsync(current => current.Id == id && current.CompanyId == companyId, cancellationToken);
        if (item is null)
        {
            return NotFound();
        }

        ((dynamic)item).SetActive(isActive);
        await _db.SaveChangesAsync(cancellationToken);
        return Ok(toDto(item));
    }

    private static HotelPropertyDto ToDto(HotelProperty item) => new(item.Id, item.Name, item.Country, item.City, item.Address, item.Phone, item.Email, item.IsActive);

    private static HotelRoomTypeDto ToDto(HotelRoomType item) => new(item.Id, item.Code, item.Name, item.Capacity, item.Description, item.IsActive);

    private static HotelMealPlanDto ToDto(HotelMealPlan item) => new(item.Id, item.Code, item.Name, item.Description, item.IsActive);

    private static HotelAgentDto ToDto(HotelAgent item) => new(item.Id, item.Name, item.ContactName, item.Email, item.Phone, item.Currency, item.IsActive);
}
