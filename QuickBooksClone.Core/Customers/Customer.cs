using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Customers;

public sealed class Customer : EntityBase, ITenantEntity
{
    public static readonly Guid DefaultCompanyId = Guid.Parse("11111111-1111-1111-1111-111111111111");

    public Customer(
        string displayName,
        string? companyName,
        string? email,
        string? phone,
        string currency,
        decimal openingBalance,
        Guid? companyId = null)
    {
        CompanyId = companyId ?? DefaultCompanyId;
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
    public decimal CreditBalance { get; private set; }
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

    public void AddCredit(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Credit amount must be greater than zero.");
        }

        CreditBalance += amount;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void UseCredit(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Credit amount must be greater than zero.");
        }

        if (amount > CreditBalance)
        {
            throw new InvalidOperationException("Credit amount exceeds customer available credit.");
        }

        CreditBalance -= amount;
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
