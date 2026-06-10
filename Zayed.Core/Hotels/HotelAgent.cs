using Zayed.Core.Common;

namespace Zayed.Core.Hotels;

public sealed class HotelAgent : EntityBase, ITenantEntity
{
    private HotelAgent()
    {
        CompanyId = Guid.Empty;
        Name = string.Empty;
        Currency = string.Empty;
    }

    public HotelAgent(string name, string? contactName, string? email, string? phone, string currency, Guid companyId)
    {
        CompanyId = companyId;
        Name = NormalizeRequired(name, nameof(name));
        ContactName = NormalizeOptional(contactName);
        Email = NormalizeOptional(email);
        Phone = NormalizeOptional(phone);
        Currency = string.IsNullOrWhiteSpace(currency) ? "SAR" : currency.Trim().ToUpperInvariant();
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public string Name { get; private set; }
    public string? ContactName { get; private set; }
    public string? Email { get; private set; }
    public string? Phone { get; private set; }
    public string Currency { get; private set; }
    public bool IsActive { get; private set; }

    public void Update(string name, string? contactName, string? email, string? phone, string currency)
    {
        Name = NormalizeRequired(name, nameof(name));
        ContactName = NormalizeOptional(contactName);
        Email = NormalizeOptional(email);
        Phone = NormalizeOptional(phone);
        Currency = string.IsNullOrWhiteSpace(currency) ? "SAR" : currency.Trim().ToUpperInvariant();
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
