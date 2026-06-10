using Zayed.Core.Common;

namespace Zayed.Core.Hotels;

public sealed class HotelProperty : EntityBase, ITenantEntity
{
    private HotelProperty()
    {
        CompanyId = Guid.Empty;
        Name = string.Empty;
        Country = string.Empty;
        City = string.Empty;
    }

    public HotelProperty(string name, string country, string city, string? address, string? phone, string? email, Guid companyId)
    {
        CompanyId = companyId;
        Name = NormalizeRequired(name, nameof(name));
        Country = string.IsNullOrWhiteSpace(country) ? "Saudi Arabia" : country.Trim();
        City = NormalizeRequired(city, nameof(city));
        Address = NormalizeOptional(address);
        Phone = NormalizeOptional(phone);
        Email = NormalizeOptional(email);
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public string Name { get; private set; }
    public string Country { get; private set; }
    public string City { get; private set; }
    public string? Address { get; private set; }
    public string? Phone { get; private set; }
    public string? Email { get; private set; }
    public bool IsActive { get; private set; }

    public void Update(string name, string country, string city, string? address, string? phone, string? email)
    {
        Name = NormalizeRequired(name, nameof(name));
        Country = string.IsNullOrWhiteSpace(country) ? "Saudi Arabia" : country.Trim();
        City = NormalizeRequired(city, nameof(city));
        Address = NormalizeOptional(address);
        Phone = NormalizeOptional(phone);
        Email = NormalizeOptional(email);
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
