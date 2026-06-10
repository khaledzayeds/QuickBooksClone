namespace Zayed.Api.Contracts.Hotels;

public sealed record HotelPropertyDto(
    Guid Id,
    string Name,
    string Country,
    string City,
    string? Address,
    string? Phone,
    string? Email,
    bool IsActive);

public sealed record UpsertHotelPropertyRequest(
    string Name,
    string? Country,
    string City,
    string? Address,
    string? Phone,
    string? Email);

public sealed record HotelRoomTypeDto(
    Guid Id,
    string Code,
    string Name,
    int Capacity,
    string? Description,
    bool IsActive);

public sealed record UpsertHotelRoomTypeRequest(
    string Code,
    string Name,
    int Capacity,
    string? Description);

public sealed record HotelMealPlanDto(
    Guid Id,
    string Code,
    string Name,
    string? Description,
    bool IsActive);

public sealed record UpsertHotelMealPlanRequest(
    string Code,
    string Name,
    string? Description);

public sealed record HotelAgentDto(
    Guid Id,
    string Name,
    string? ContactName,
    string? Email,
    string? Phone,
    string Currency,
    bool IsActive);

public sealed record UpsertHotelAgentRequest(
    string Name,
    string? ContactName,
    string? Email,
    string? Phone,
    string? Currency);

public sealed record SetHotelMasterDataActiveRequest(bool IsActive);
