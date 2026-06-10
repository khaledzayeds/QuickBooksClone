using Zayed.Core.Common;

namespace Zayed.Core.Hotels;

public sealed class HotelAllotment : EntityBase, ITenantEntity
{
    private HotelAllotment()
    {
        CompanyId = Guid.Empty;
        AllotmentType = string.Empty;
    }

    public HotelAllotment(
        Guid contractId,
        Guid hotelId,
        Guid? agentId,
        DateOnly startDate,
        DateOnly endDate,
        int rooms,
        string allotmentType,
        bool isOverAllotment,
        Guid companyId)
    {
        if (contractId == Guid.Empty) throw new ArgumentException("Contract is required.", nameof(contractId));
        if (hotelId == Guid.Empty) throw new ArgumentException("Hotel is required.", nameof(hotelId));

        CompanyId = companyId;
        ContractId = contractId;
        HotelId = hotelId;
        AgentId = agentId;
        StartDate = startDate;
        EndDate = endDate < startDate ? startDate : endDate;
        Rooms = rooms <= 0 ? 1 : rooms;
        AllotmentType = string.IsNullOrWhiteSpace(allotmentType) ? "hotel" : allotmentType.Trim().ToLowerInvariant();
        IsOverAllotment = isOverAllotment;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public Guid ContractId { get; private set; }
    public Guid HotelId { get; private set; }
    public Guid? AgentId { get; private set; }
    public DateOnly StartDate { get; private set; }
    public DateOnly EndDate { get; private set; }
    public int Rooms { get; private set; }
    public string AllotmentType { get; private set; }
    public bool IsOverAllotment { get; private set; }
    public bool IsActive { get; private set; }

    public void Update(Guid contractId, Guid hotelId, Guid? agentId, DateOnly startDate, DateOnly endDate, int rooms, string allotmentType, bool isOverAllotment)
    {
        ContractId = contractId;
        HotelId = hotelId;
        AgentId = agentId;
        StartDate = startDate;
        EndDate = endDate < startDate ? startDate : endDate;
        Rooms = rooms <= 0 ? 1 : rooms;
        AllotmentType = string.IsNullOrWhiteSpace(allotmentType) ? "hotel" : allotmentType.Trim().ToLowerInvariant();
        IsOverAllotment = isOverAllotment;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SetActive(bool isActive)
    {
        IsActive = isActive;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
