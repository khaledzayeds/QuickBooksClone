using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Vendors;

public sealed class Vendor : EntityBase, ITenantEntity
{
    public Vendor(
        string displayName,
        string? companyName,
        string? email,
        string? phone,
        string currency,
        decimal openingBalance,
        Guid? companyId = null)
    {
        if (openingBalance < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(openingBalance), "Opening balance cannot be negative.");
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        DisplayName = NormalizeRequired(displayName, nameof(displayName));
        CompanyName = NormalizeOptional(companyName);
        Email = NormalizeOptional(email);
        Phone = NormalizeOptional(phone);
        Currency = string.IsNullOrWhiteSpace(currency) ? "EGP" : currency.Trim().ToUpperInvariant();
        Balance = openingBalance;
        IsActive = true;
    }

    public Guid CompanyId { get; }
    public string DisplayName { get; private set; }
    public string? CompanyName { get; private set; }
    public string? Email { get; private set; }
    public string? Phone { get; private set; }
    public string Currency { get; private set; }
    public decimal Balance { get; private set; }
    public bool IsActive { get; private set; }

    public void Update(string displayName, string? companyName, string? email, string? phone, string currency)
    {
        DisplayName = NormalizeRequired(displayName, nameof(displayName));
        CompanyName = NormalizeOptional(companyName);
        Email = NormalizeOptional(email);
        Phone = NormalizeOptional(phone);
        Currency = string.IsNullOrWhiteSpace(currency) ? "EGP" : currency.Trim().ToUpperInvariant();
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SetActive(bool isActive)
    {
        IsActive = isActive;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ApplyBill(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Bill amount must be greater than zero.");
        }

        Balance += amount;
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

    private static string? NormalizeOptional(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
