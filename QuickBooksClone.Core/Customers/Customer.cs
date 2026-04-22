using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Customers;

public sealed class Customer : EntityBase, ITenantEntity
{
    public static readonly Guid DefaultCompanyId = Guid.Parse("11111111-1111-1111-1111-111111111111");

    private Customer()
    {
        CompanyId = Guid.Empty;
        DisplayName = string.Empty;
        Currency = string.Empty;
    }

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

    public void ApplyInvoice(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Invoice amount must be greater than zero.");
        }

        Balance += amount;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ReverseInvoice(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Invoice amount must be greater than zero.");
        }

        if (amount > Balance)
        {
            throw new InvalidOperationException("Invoice reversal amount cannot exceed customer balance.");
        }

        Balance -= amount;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ApplyPayment(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Payment amount must be greater than zero.");
        }

        if (amount > Balance)
        {
            throw new InvalidOperationException("Payment amount cannot exceed customer balance.");
        }

        Balance -= amount;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ReversePayment(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Payment amount must be greater than zero.");
        }

        Balance += amount;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ApplySalesReturn(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Return amount must be greater than zero.");
        }

        var receivableReduction = Math.Min(Balance, amount);
        Balance -= receivableReduction;
        CreditBalance += amount - receivableReduction;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ReverseSalesReturn(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Return amount must be greater than zero.");
        }

        var creditReduction = Math.Min(CreditBalance, amount);
        CreditBalance -= creditReduction;
        Balance += amount - creditReduction;
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

    public void ApplyCreditToInvoice(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Credit amount must be greater than zero.");
        }

        if (amount > CreditBalance)
        {
            throw new InvalidOperationException("Credit amount exceeds customer available credit.");
        }

        if (amount > Balance)
        {
            throw new InvalidOperationException("Credit amount cannot exceed customer balance.");
        }

        CreditBalance -= amount;
        Balance -= amount;
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
