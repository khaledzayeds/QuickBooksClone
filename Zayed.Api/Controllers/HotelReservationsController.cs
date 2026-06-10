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
[Route("api/hotels/reservations")]
public sealed class HotelReservationsController : ControllerBase
{
    private readonly ZayedDbContext _db;
    private readonly ICompanyRuntimeService _runtime;
    private readonly ICompanyModuleAccessService _modules;

    public HotelReservationsController(ZayedDbContext db, ICompanyRuntimeService runtime, ICompanyModuleAccessService modules)
    {
        _db = db;
        _runtime = runtime;
        _modules = modules;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<HotelReservationDto>>> GetReservations([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var reservations = await _db.HotelReservations
            .Where(item => item.CompanyId == companyId && (includeInactive || item.IsActive))
            .OrderByDescending(item => item.CheckIn)
            .ThenBy(item => item.ReservationNumber)
            .ToListAsync(cancellationToken);

        return Ok(await ToDtosAsync(reservations, cancellationToken));
    }

    [HttpPost]
    public async Task<ActionResult<HotelReservationDto>> CreateReservation(UpsertHotelReservationRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var number = request.ReservationNumber.Trim();
        if (await _db.HotelReservations.AnyAsync(item => item.CompanyId == companyId && item.ReservationNumber == number, cancellationToken))
        {
            return Conflict("Reservation number already exists.");
        }

        var prepared = await PrepareReservationAsync(companyId, request, null, cancellationToken);
        if (prepared.Result is not null) return prepared.Result;

        var reservation = new HotelReservation(
            number,
            request.ContractId,
            request.HotelId,
            request.AgentId,
            request.RoomTypeId,
            request.MealPlanId,
            request.GuestName,
            request.GuestPhone,
            request.CheckIn,
            request.CheckOut,
            request.Rooms,
            request.Adults,
            request.Children,
            prepared.NightlyRate,
            companyId);

        _db.HotelReservations.Add(reservation);
        await _db.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(GetReservations), (await ToDtosAsync([reservation], cancellationToken)).Single());
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<HotelReservationDto>> UpdateReservation(Guid id, UpsertHotelReservationRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var reservation = await _db.HotelReservations.FirstOrDefaultAsync(item => item.Id == id && item.CompanyId == companyId, cancellationToken);
        if (reservation is null) return NotFound();

        var number = request.ReservationNumber.Trim();
        if (await _db.HotelReservations.AnyAsync(item => item.CompanyId == companyId && item.Id != id && item.ReservationNumber == number, cancellationToken))
        {
            return Conflict("Reservation number already exists.");
        }

        var prepared = await PrepareReservationAsync(companyId, request, id, cancellationToken);
        if (prepared.Result is not null) return prepared.Result;

        reservation.Update(
            number,
            request.ContractId,
            request.HotelId,
            request.AgentId,
            request.RoomTypeId,
            request.MealPlanId,
            request.GuestName,
            request.GuestPhone,
            request.CheckIn,
            request.CheckOut,
            request.Rooms,
            request.Adults,
            request.Children,
            prepared.NightlyRate);

        await _db.SaveChangesAsync(cancellationToken);
        return Ok((await ToDtosAsync([reservation], cancellationToken)).Single());
    }

    [HttpPatch("{id:guid}/active")]
    public async Task<ActionResult<HotelReservationDto>> SetReservationActive(Guid id, SetHotelMasterDataActiveRequest request, CancellationToken cancellationToken = default)
    {
        if (await ValidateModuleAsync(cancellationToken) is { } forbidden) return forbidden;
        var companyId = GetCompanyId();
        var reservation = await _db.HotelReservations.FirstOrDefaultAsync(item => item.Id == id && item.CompanyId == companyId, cancellationToken);
        if (reservation is null) return NotFound();
        reservation.SetActive(request.IsActive);
        await _db.SaveChangesAsync(cancellationToken);
        return Ok((await ToDtosAsync([reservation], cancellationToken)).Single());
    }

    private async Task<ActionResult?> ValidateModuleAsync(CancellationToken cancellationToken)
    {
        try
        {
            await _modules.RequireModuleAsync(ModuleCodes.HotelReservations, cancellationToken);
            return null;
        }
        catch (ModuleNotEnabledException exception)
        {
            return StatusCode(StatusCodes.Status403Forbidden, exception.Message);
        }
    }

    private Guid GetCompanyId() => _runtime.Current.CompanyId ?? throw new InvalidOperationException("No active company is open.");

    private async Task<(ActionResult? Result, decimal NightlyRate)> PrepareReservationAsync(Guid companyId, UpsertHotelReservationRequest request, Guid? existingReservationId, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.ReservationNumber)) return (BadRequest("Reservation number is required."), 0);
        if (string.IsNullOrWhiteSpace(request.GuestName)) return (BadRequest("Guest name is required."), 0);

        var contract = await _db.HotelContracts
            .Include(item => item.Rates)
            .FirstOrDefaultAsync(item => item.CompanyId == companyId && item.Id == request.ContractId && item.IsActive, cancellationToken);
        if (contract is null) return (BadRequest("Active contract is required."), 0);
        if (request.CheckIn < contract.StartDate || request.CheckOut > contract.EndDate.AddDays(1))
        {
            return (BadRequest("Reservation dates must be within the selected contract period."), 0);
        }
        if (contract.HotelId != request.HotelId) return (BadRequest("Selected hotel must match the contract."), 0);
        if (request.AgentId is Guid agentId && contract.AgentId is Guid contractAgentId && agentId != contractAgentId)
        {
            return (BadRequest("Selected agent must match the contract agent."), 0);
        }

        if (!await _db.HotelProperties.AnyAsync(item => item.CompanyId == companyId && item.Id == request.HotelId && item.IsActive, cancellationToken))
        {
            return (BadRequest("Active hotel is required."), 0);
        }
        if (!await _db.HotelRoomTypes.AnyAsync(item => item.CompanyId == companyId && item.Id == request.RoomTypeId && item.IsActive, cancellationToken))
        {
            return (BadRequest("Active room type is required."), 0);
        }
        if (!await _db.HotelMealPlans.AnyAsync(item => item.CompanyId == companyId && item.Id == request.MealPlanId && item.IsActive, cancellationToken))
        {
            return (BadRequest("Active meal plan is required."), 0);
        }
        if (request.AgentId is Guid selectedAgentId && !await _db.HotelAgents.AnyAsync(item => item.CompanyId == companyId && item.Id == selectedAgentId && item.IsActive, cancellationToken))
        {
            return (BadRequest("Selected agent is not active."), 0);
        }

        var rate = contract.Rates.FirstOrDefault(item => item.RoomTypeId == request.RoomTypeId && item.MealPlanId == request.MealPlanId)?.Rate
            ?? request.NightlyRate.GetValueOrDefault();
        var availableRooms = await GetAvailableRoomsAsync(companyId, request.ContractId, request.HotelId, request.CheckIn, request.CheckOut, existingReservationId, cancellationToken);
        var hasAllotment = await HasAllotmentAsync(companyId, request.ContractId, request.HotelId, request.CheckIn, request.CheckOut, cancellationToken);
        if (hasAllotment && request.Rooms > availableRooms)
        {
            return (Conflict("Not enough allotment available for selected dates."), rate);
        }

        return (null, rate);
    }

    private async Task<bool> HasAllotmentAsync(Guid companyId, Guid contractId, Guid hotelId, DateOnly checkIn, DateOnly checkOut, CancellationToken cancellationToken)
    {
        return await _db.HotelAllotments.AnyAsync(item =>
            item.CompanyId == companyId &&
            item.ContractId == contractId &&
            item.HotelId == hotelId &&
            item.IsActive &&
            !item.IsOverAllotment &&
            item.StartDate < checkOut &&
            item.EndDate > checkIn, cancellationToken);
    }

    private async Task<int> GetAvailableRoomsAsync(Guid companyId, Guid contractId, Guid hotelId, DateOnly checkIn, DateOnly checkOut, Guid? existingReservationId, CancellationToken cancellationToken)
    {
        var allottedRooms = await _db.HotelAllotments
            .Where(item =>
                item.CompanyId == companyId &&
                item.ContractId == contractId &&
                item.HotelId == hotelId &&
                item.IsActive &&
                !item.IsOverAllotment &&
                item.StartDate < checkOut &&
                item.EndDate > checkIn)
            .SumAsync(item => (int?)item.Rooms, cancellationToken) ?? 0;

        var reservedRooms = await _db.HotelReservations
            .Where(item =>
                item.CompanyId == companyId &&
                item.ContractId == contractId &&
                item.HotelId == hotelId &&
                item.IsActive &&
                (!existingReservationId.HasValue || item.Id != existingReservationId.Value) &&
                item.CheckIn < checkOut &&
                item.CheckOut > checkIn)
            .SumAsync(item => (int?)item.Rooms, cancellationToken) ?? 0;

        return Math.Max(0, allottedRooms - reservedRooms);
    }

    private async Task<IReadOnlyList<HotelReservationDto>> ToDtosAsync(IReadOnlyList<HotelReservation> reservations, CancellationToken cancellationToken)
    {
        var companyId = GetCompanyId();
        var contracts = await _db.HotelContracts.Where(item => item.CompanyId == companyId).ToDictionaryAsync(item => item.Id, item => item.ContractNumber, cancellationToken);
        var hotels = await _db.HotelProperties.Where(item => item.CompanyId == companyId).ToDictionaryAsync(item => item.Id, item => item.Name, cancellationToken);
        var agents = await _db.HotelAgents.Where(item => item.CompanyId == companyId).ToDictionaryAsync(item => item.Id, item => item.Name, cancellationToken);
        var roomTypes = await _db.HotelRoomTypes.Where(item => item.CompanyId == companyId).ToDictionaryAsync(item => item.Id, item => item.Name, cancellationToken);
        var mealPlans = await _db.HotelMealPlans.Where(item => item.CompanyId == companyId).ToDictionaryAsync(item => item.Id, item => item.Name, cancellationToken);

        var result = new List<HotelReservationDto>(reservations.Count);
        foreach (var item in reservations)
        {
            var availableRooms = await GetAvailableRoomsAsync(companyId, item.ContractId, item.HotelId, item.CheckIn, item.CheckOut, item.Id, cancellationToken);
            result.Add(new HotelReservationDto(
                item.Id,
                item.ReservationNumber,
                item.ContractId,
                contracts.GetValueOrDefault(item.ContractId, "Contract"),
                item.HotelId,
                hotels.GetValueOrDefault(item.HotelId, "Hotel"),
                item.AgentId,
                item.AgentId is Guid agentId ? agents.GetValueOrDefault(agentId) : null,
                item.RoomTypeId,
                roomTypes.GetValueOrDefault(item.RoomTypeId, "Room"),
                item.MealPlanId,
                mealPlans.GetValueOrDefault(item.MealPlanId, "Meal"),
                item.GuestName,
                item.GuestPhone,
                item.CheckIn,
                item.CheckOut,
                item.Nights,
                item.Rooms,
                item.Adults,
                item.Children,
                item.NightlyRate,
                item.TotalAmount,
                item.Status,
                item.IsActive,
                availableRooms));
        }

        return result;
    }
}
