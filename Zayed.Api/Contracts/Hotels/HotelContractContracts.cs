namespace Zayed.Api.Contracts.Hotels;

public sealed record HotelContractRateDto(
    Guid Id,
    Guid RoomTypeId,
    string RoomTypeName,
    Guid MealPlanId,
    string MealPlanName,
    decimal Rate);

public sealed record HotelContractDto(
    Guid Id,
    string ContractNumber,
    Guid HotelId,
    string HotelName,
    Guid? AgentId,
    string? AgentName,
    DateOnly StartDate,
    DateOnly EndDate,
    string Currency,
    string? Notes,
    bool IsActive,
    IReadOnlyList<HotelContractRateDto> Rates);

public sealed record UpsertHotelContractRateRequest(
    Guid RoomTypeId,
    Guid MealPlanId,
    decimal Rate);

public sealed record UpsertHotelContractRequest(
    string ContractNumber,
    Guid HotelId,
    Guid? AgentId,
    DateOnly StartDate,
    DateOnly EndDate,
    string? Currency,
    string? Notes,
    IReadOnlyList<UpsertHotelContractRateRequest>? Rates);

public sealed record HotelAllotmentDto(
    Guid Id,
    Guid ContractId,
    string ContractNumber,
    Guid HotelId,
    string HotelName,
    Guid? AgentId,
    string? AgentName,
    DateOnly StartDate,
    DateOnly EndDate,
    int Rooms,
    string AllotmentType,
    bool IsOverAllotment,
    bool IsActive);

public sealed record UpsertHotelAllotmentRequest(
    Guid ContractId,
    Guid HotelId,
    Guid? AgentId,
    DateOnly StartDate,
    DateOnly EndDate,
    int Rooms,
    string? AllotmentType,
    bool IsOverAllotment);
