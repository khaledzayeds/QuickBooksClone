using Zayed.Core.Common;

namespace Zayed.Core.Hotels;

public sealed class HotelMealPlan : EntityBase, ITenantEntity
{
    private HotelMealPlan()
    {
        CompanyId = Guid.Empty;
        Code = string.Empty;
        Name = string.Empty;
    }

    public HotelMealPlan(string code, string name, string? description, Guid companyId)
    {
        CompanyId = companyId;
        Code = NormalizeRequired(code, nameof(code)).ToUpperInvariant();
        Name = NormalizeRequired(name, nameof(name));
        Description = NormalizeOptional(description);
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public string Code { get; private set; }
    public string Name { get; private set; }
    public string? Description { get; private set; }
    public bool IsActive { get; private set; }

    public void Update(string code, string name, string? description)
    {
        Code = NormalizeRequired(code, nameof(code)).ToUpperInvariant();
        Name = NormalizeRequired(name, nameof(name));
        Description = NormalizeOptional(description);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SetActive(bool isActive)
    {
        IsActive = isActive;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    private static string NormalizeRequired(string value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Value is required.", parameterName);
        }

        return value.Trim();
    }

    private static string? NormalizeOptional(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
