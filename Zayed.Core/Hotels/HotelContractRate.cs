using Zayed.Core.Common;

namespace Zayed.Core.Hotels;

public sealed class HotelContractRate : EntityBase, ITenantEntity
{
    private HotelContractRate()
    {
        CompanyId = Guid.Empty;
    }

    public HotelContractRate(Guid contractId, Guid roomTypeId, Guid mealPlanId, decimal rate, Guid companyId)
    {
        if (roomTypeId == Guid.Empty) throw new ArgumentException("Room type is required.", nameof(roomTypeId));
        if (mealPlanId == Guid.Empty) throw new ArgumentException("Meal plan is required.", nameof(mealPlanId));

        CompanyId = companyId;
        ContractId = contractId;
        RoomTypeId = roomTypeId;
        MealPlanId = mealPlanId;
        Rate = rate < 0 ? 0 : rate;
    }

    public Guid CompanyId { get; private set; }
    public Guid ContractId { get; private set; }
    public Guid RoomTypeId { get; private set; }
    public Guid MealPlanId { get; private set; }
    public decimal Rate { get; private set; }
}
