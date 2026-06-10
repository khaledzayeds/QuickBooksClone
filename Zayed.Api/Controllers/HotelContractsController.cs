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
[Route("api/hotels")]
public sealed class HotelContractsController : ControllerBase
{
    private readonly ZayedDbContext _db;
    private readonly ICompanyRuntimeService _runtime;
    private readonly ICompanyModuleAccessService _modules;

    public HotelContractsController(ZayedDbContext db, ICompanyRuntimeService runtime, ICompanyModuleAccessService modules)
    {
        _db = db;
        _runtime = runtime;
        _modules = modules;
    }

    [HttpGet("contracts")]
    public async Task<ActionResult<IReadOnlyList<HotelContractDto>>> GetContracts([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelContracts, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var contracts = await _db.HotelContracts
            .Include(contract => contract.Rates)
            .Where(contract => contract.CompanyId == companyId && (includeInactive || contract.IsActive))
            .OrderByDescending(contract => contract.StartDate)
            .ThenBy(contract => contract.ContractNumber)
            .ToListAsync(cancellationToken);
        return Ok(await ToContractDtosAsync(contracts, cancellationToken));
    }

    [HttpPost("contracts")]
    public async Task<ActionResult<HotelContractDto>> CreateContract(UpsertHotelContractRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelContracts, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var number = request.ContractNumber.Trim();
        if (await _db.HotelContracts.AnyAsync(item => item.CompanyId == companyId && item.ContractNumber == number, cancellationToken))
        {
            return Conflict("Contract number already exists.");
        }

        var validation = await ValidateContractLookupsAsync(companyId, request.HotelId, request.AgentId, cancellationToken);
        if (validation is not null) return validation;

        var contract = new HotelContract(number, request.HotelId, request.AgentId, request.StartDate, request.EndDate, request.Currency ?? "SAR", request.Notes, companyId);
        contract.ReplaceRates(BuildRates(contract.Id, request.Rates, companyId));
        _db.HotelContracts.Add(contract);
        await _db.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(GetContracts), (await ToContractDtosAsync([contract], cancellationToken)).Single());
    }

    [HttpPut("contracts/{id:guid}")]
    public async Task<ActionResult<HotelContractDto>> UpdateContract(Guid id, UpsertHotelContractRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelContracts, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var contract = await _db.HotelContracts
            .Include(item => item.Rates)
            .FirstOrDefaultAsync(item => item.Id == id && item.CompanyId == companyId, cancellationToken);
        if (contract is null) return NotFound();

        var number = request.ContractNumber.Trim();
        if (await _db.HotelContracts.AnyAsync(item => item.CompanyId == companyId && item.Id != id && item.ContractNumber == number, cancellationToken))
        {
            return Conflict("Contract number already exists.");
        }

        var validation = await ValidateContractLookupsAsync(companyId, request.HotelId, request.AgentId, cancellationToken);
        if (validation is not null) return validation;

        contract.Update(number, request.HotelId, request.AgentId, request.StartDate, request.EndDate, request.Currency ?? "SAR", request.Notes);
        contract.ReplaceRates(BuildRates(contract.Id, request.Rates, companyId));
        await _db.SaveChangesAsync(cancellationToken);
        return Ok((await ToContractDtosAsync([contract], cancellationToken)).Single());
    }

    [HttpPatch("contracts/{id:guid}/active")]
    public async Task<ActionResult<HotelContractDto>> SetContractActive(Guid id, SetHotelMasterDataActiveRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelContracts, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var contract = await _db.HotelContracts
            .Include(item => item.Rates)
            .FirstOrDefaultAsync(item => item.Id == id && item.CompanyId == companyId, cancellationToken);
        if (contract is null) return NotFound();
        contract.SetActive(request.IsActive);
        await _db.SaveChangesAsync(cancellationToken);
        return Ok((await ToContractDtosAsync([contract], cancellationToken)).Single());
    }

    [HttpGet("allotments")]
    public async Task<ActionResult<IReadOnlyList<HotelAllotmentDto>>> GetAllotments([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelAllotment, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var items = await _db.HotelAllotments
            .Where(item => item.CompanyId == companyId && (includeInactive || item.IsActive))
            .OrderByDescending(item => item.StartDate)
            .ToListAsync(cancellationToken);
        return Ok(await ToAllotmentDtosAsync(items, cancellationToken));
    }

    [HttpPost("allotments")]
    public async Task<ActionResult<HotelAllotmentDto>> CreateAllotment(UpsertHotelAllotmentRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelAllotment, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var validation = await ValidateAllotmentLookupsAsync(companyId, request, cancellationToken);
        if (validation is not null) return validation;

        var item = new HotelAllotment(request.ContractId, request.HotelId, request.AgentId, request.StartDate, request.EndDate, request.Rooms, request.AllotmentType ?? "hotel", request.IsOverAllotment, companyId);
        _db.HotelAllotments.Add(item);
        await _db.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(GetAllotments), (await ToAllotmentDtosAsync([item], cancellationToken)).Single());
    }

    [HttpPut("allotments/{id:guid}")]
    public async Task<ActionResult<HotelAllotmentDto>> UpdateAllotment(Guid id, UpsertHotelAllotmentRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelAllotment, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var item = await _db.HotelAllotments.FirstOrDefaultAsync(current => current.Id == id && current.CompanyId == companyId, cancellationToken);
        if (item is null) return NotFound();

        var validation = await ValidateAllotmentLookupsAsync(companyId, request, cancellationToken);
        if (validation is not null) return validation;

        item.Update(request.ContractId, request.HotelId, request.AgentId, request.StartDate, request.EndDate, request.Rooms, request.AllotmentType ?? "hotel", request.IsOverAllotment);
        await _db.SaveChangesAsync(cancellationToken);
        return Ok((await ToAllotmentDtosAsync([item], cancellationToken)).Single());
    }

    [HttpPatch("allotments/{id:guid}/active")]
    public async Task<ActionResult<HotelAllotmentDto>> SetAllotmentActive(Guid id, SetHotelMasterDataActiveRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(ModuleCodes.HotelAllotment, cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var item = await _db.HotelAllotments.FirstOrDefaultAsync(current => current.Id == id && current.CompanyId == companyId, cancellationToken);
        if (item is null) return NotFound();
        item.SetActive(request.IsActive);
        await _db.SaveChangesAsync(cancellationToken);
        return Ok((await ToAllotmentDtosAsync([item], cancellationToken)).Single());
    }

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

    private Guid GetCompanyId() => _runtime.Current.CompanyId ?? throw new InvalidOperationException("No active company is open.");

    private async Task<ActionResult?> ValidateContractLookupsAsync(Guid companyId, Guid hotelId, Guid? agentId, CancellationToken cancellationToken)
    {
        if (!await _db.HotelProperties.AnyAsync(item => item.CompanyId == companyId && item.Id == hotelId && item.IsActive, cancellationToken))
        {
            return BadRequest("Active hotel is required.");
        }
        if (agentId is Guid agent && !await _db.HotelAgents.AnyAsync(item => item.CompanyId == companyId && item.Id == agent && item.IsActive, cancellationToken))
        {
            return BadRequest("Selected agent is not active.");
        }
        return null;
    }

    private async Task<ActionResult?> ValidateAllotmentLookupsAsync(Guid companyId, UpsertHotelAllotmentRequest request, CancellationToken cancellationToken)
    {
        if (!await _db.HotelContracts.AnyAsync(item => item.CompanyId == companyId && item.Id == request.ContractId && item.IsActive, cancellationToken))
        {
            return BadRequest("Active contract is required.");
        }
        return await ValidateContractLookupsAsync(companyId, request.HotelId, request.AgentId, cancellationToken);
    }

    private static IReadOnlyList<HotelContractRate> BuildRates(Guid contractId, IReadOnlyList<UpsertHotelContractRateRequest>? rates, Guid companyId)
    {
        return (rates ?? [])
            .Where(rate => rate.RoomTypeId != Guid.Empty && rate.MealPlanId != Guid.Empty)
            .GroupBy(rate => new { rate.RoomTypeId, rate.MealPlanId })
            .Select(group => group.First())
            .Select(rate => new HotelContractRate(contractId, rate.RoomTypeId, rate.MealPlanId, rate.Rate, companyId))
            .ToList();
    }

    private async Task<IReadOnlyList<HotelContractDto>> ToContractDtosAsync(IReadOnlyList<HotelContract> contracts, CancellationToken cancellationToken)
    {
        var companyId = GetCompanyId();
        var hotels = await _db.HotelProperties.Where(item => item.CompanyId == companyId).ToDictionaryAsync(item => item.Id, item => item.Name, cancellationToken);
        var agents = await _db.HotelAgents.Where(item => item.CompanyId == companyId).ToDictionaryAsync(item => item.Id, item => item.Name, cancellationToken);
        var roomTypes = await _db.HotelRoomTypes.Where(item => item.CompanyId == companyId).ToDictionaryAsync(item => item.Id, item => item.Name, cancellationToken);
        var mealPlans = await _db.HotelMealPlans.Where(item => item.CompanyId == companyId).ToDictionaryAsync(item => item.Id, item => item.Name, cancellationToken);

        return contracts.Select(contract => new HotelContractDto(
            contract.Id,
            contract.ContractNumber,
            contract.HotelId,
            hotels.GetValueOrDefault(contract.HotelId, "Hotel"),
            contract.AgentId,
            contract.AgentId is Guid agentId ? agents.GetValueOrDefault(agentId) : null,
            contract.StartDate,
            contract.EndDate,
            contract.Currency,
            contract.Notes,
            contract.IsActive,
            contract.Rates.Select(rate => new HotelContractRateDto(
                rate.Id,
                rate.RoomTypeId,
                roomTypes.GetValueOrDefault(rate.RoomTypeId, "Room"),
                rate.MealPlanId,
                mealPlans.GetValueOrDefault(rate.MealPlanId, "Meal"),
                rate.Rate)).ToList())).ToList();
    }

    private async Task<IReadOnlyList<HotelAllotmentDto>> ToAllotmentDtosAsync(IReadOnlyList<HotelAllotment> allotments, CancellationToken cancellationToken)
    {
        var companyId = GetCompanyId();
        var contracts = await _db.HotelContracts.Where(item => item.CompanyId == companyId).ToDictionaryAsync(item => item.Id, item => item.ContractNumber, cancellationToken);
        var hotels = await _db.HotelProperties.Where(item => item.CompanyId == companyId).ToDictionaryAsync(item => item.Id, item => item.Name, cancellationToken);
        var agents = await _db.HotelAgents.Where(item => item.CompanyId == companyId).ToDictionaryAsync(item => item.Id, item => item.Name, cancellationToken);

        return allotments.Select(item => new HotelAllotmentDto(
            item.Id,
            item.ContractId,
            contracts.GetValueOrDefault(item.ContractId, "Contract"),
            item.HotelId,
            hotels.GetValueOrDefault(item.HotelId, "Hotel"),
            item.AgentId,
            item.AgentId is Guid agentId ? agents.GetValueOrDefault(agentId) : null,
            item.StartDate,
            item.EndDate,
            item.Rooms,
            item.AllotmentType,
            item.IsOverAllotment,
            item.IsActive)).ToList();
    }
}
