using Zayed.Core.Common;

namespace Zayed.Core.Hotels;

public sealed class HotelReservation : EntityBase, ITenantEntity
{
    private HotelReservation()
    {
        CompanyId = Guid.Empty;
        ReservationNumber = string.Empty;
        GuestName = string.Empty;
        GuestPhone = null;
        Status = string.Empty;
    }

    public HotelReservation(
        string reservationNumber,
        Guid contractId,
        Guid hotelId,
        Guid? agentId,
        Guid roomTypeId,
        Guid mealPlanId,
        string guestName,
        string? guestPhone,
        DateOnly checkIn,
        DateOnly checkOut,
        int rooms,
        int adults,
        int children,
        decimal nightlyRate,
        Guid companyId)
    {
        CompanyId = companyId;
        ReservationNumber = NormalizeRequired(reservationNumber, nameof(reservationNumber));
        Apply(contractId, hotelId, agentId, roomTypeId, mealPlanId, guestName, guestPhone, checkIn, checkOut, rooms, adults, children, nightlyRate);
        Status = "confirmed";
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public string ReservationNumber { get; private set; } = string.Empty;
    public Guid ContractId { get; private set; }
    public Guid HotelId { get; private set; }
    public Guid? AgentId { get; private set; }
    public Guid RoomTypeId { get; private set; }
    public Guid MealPlanId { get; private set; }
    public string GuestName { get; private set; } = string.Empty;
    public string? GuestPhone { get; private set; }
    public DateOnly CheckIn { get; private set; }
    public DateOnly CheckOut { get; private set; }
    public int Rooms { get; private set; }
    public int Adults { get; private set; }
    public int Children { get; private set; }
    public decimal NightlyRate { get; private set; }
    public decimal TotalAmount { get; private set; }
    public string Status { get; private set; } = string.Empty;
    public bool IsActive { get; private set; }

    public int Nights => Math.Max(1, CheckOut.DayNumber - CheckIn.DayNumber);

    public void Update(
        string reservationNumber,
        Guid contractId,
        Guid hotelId,
        Guid? agentId,
        Guid roomTypeId,
        Guid mealPlanId,
        string guestName,
        string? guestPhone,
        DateOnly checkIn,
        DateOnly checkOut,
        int rooms,
        int adults,
        int children,
        decimal nightlyRate)
    {
        ReservationNumber = NormalizeRequired(reservationNumber, nameof(reservationNumber));
        Apply(contractId, hotelId, agentId, roomTypeId, mealPlanId, guestName, guestPhone, checkIn, checkOut, rooms, adults, children, nightlyRate);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SetActive(bool isActive)
    {
        IsActive = isActive;
        Status = isActive ? "confirmed" : "cancelled";
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    private void Apply(
        Guid contractId,
        Guid hotelId,
        Guid? agentId,
        Guid roomTypeId,
        Guid mealPlanId,
        string guestName,
        string? guestPhone,
        DateOnly checkIn,
        DateOnly checkOut,
        int rooms,
        int adults,
        int children,
        decimal nightlyRate)
    {
        if (contractId == Guid.Empty) throw new ArgumentException("Contract is required.", nameof(contractId));
        if (hotelId == Guid.Empty) throw new ArgumentException("Hotel is required.", nameof(hotelId));
        if (roomTypeId == Guid.Empty) throw new ArgumentException("Room type is required.", nameof(roomTypeId));
        if (mealPlanId == Guid.Empty) throw new ArgumentException("Meal plan is required.", nameof(mealPlanId));

        ContractId = contractId;
        HotelId = hotelId;
        AgentId = agentId;
        RoomTypeId = roomTypeId;
        MealPlanId = mealPlanId;
        GuestName = NormalizeRequired(guestName, nameof(guestName));
        GuestPhone = NormalizeOptional(guestPhone);
        CheckIn = checkIn;
        CheckOut = checkOut <= checkIn ? checkIn.AddDays(1) : checkOut;
        Rooms = rooms <= 0 ? 1 : rooms;
        Adults = adults <= 0 ? 1 : adults;
        Children = Math.Max(0, children);
        NightlyRate = nightlyRate < 0 ? 0 : nightlyRate;
        TotalAmount = Rooms * Nights * NightlyRate;
    }

    private static string NormalizeRequired(string value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value)) throw new ArgumentException("Value is required.", parameterName);
        return value.Trim();
    }

    private static string? NormalizeOptional(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
