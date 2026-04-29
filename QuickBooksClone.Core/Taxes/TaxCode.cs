using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Taxes;

public sealed class TaxCode : EntityBase, ITenantEntity
{
    public static readonly Guid DefaultCompanyId = Guid.Parse("11111111-1111-1111-1111-111111111111");

    private TaxCode()
    {
        CompanyId = Guid.Empty;
        Code = string.Empty;
        Name = string.Empty;
    }

    public TaxCode(
        string code,
        string name,
        TaxCodeScope scope,
        decimal ratePercent,
        Guid taxAccountId,
        string? description = null,
        Guid? companyId = null)
    {
        CompanyId = companyId ?? DefaultCompanyId;
        Code = NormalizeRequired(code, nameof(code), 40).ToUpperInvariant();
        Name = NormalizeRequired(name, nameof(name), 120);
        Scope = scope;
        RatePercent = NormalizeRate(ratePercent);
        TaxAccountId = taxAccountId == Guid.Empty ? throw new ArgumentException("Tax account is required.", nameof(taxAccountId)) : taxAccountId;
        Description = NormalizeOptional(description, 500);
        IsActive = true;
    }

    public Guid CompanyId { get; }
    public string Code { get; private set; }
    public string Name { get; private set; }
    public TaxCodeScope Scope { get; private set; }
    public decimal RatePercent { get; private set; }
    public Guid TaxAccountId { get; private set; }
    public string? Description { get; private set; }
    public bool IsActive { get; private set; }

    public bool CanApplyTo(TaxTransactionType transactionType) =>
        Scope == TaxCodeScope.Both ||
        (Scope == TaxCodeScope.Sales && transactionType == TaxTransactionType.Sales) ||
        (Scope == TaxCodeScope.Purchase && transactionType == TaxTransactionType.Purchase);

    public void Update(string code, string name, TaxCodeScope scope, decimal ratePercent, Guid taxAccountId, string? description)
    {
        Code = NormalizeRequired(code, nameof(code), 40).ToUpperInvariant();
        Name = NormalizeRequired(name, nameof(name), 120);
        Scope = scope;
        RatePercent = NormalizeRate(ratePercent);
        TaxAccountId = taxAccountId == Guid.Empty ? throw new ArgumentException("Tax account is required.", nameof(taxAccountId)) : taxAccountId;
        Description = NormalizeOptional(description, 500);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SetActive(bool isActive)
    {
        IsActive = isActive;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    private static decimal NormalizeRate(decimal ratePercent)
    {
        if (ratePercent is < 0 or > 100)
        {
            throw new ArgumentOutOfRangeException(nameof(ratePercent), "Tax rate must be between 0 and 100.");
        }

        return ratePercent;
    }

    private static string NormalizeRequired(string value, string parameterName, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Value is required.", parameterName);
        }

        var normalized = value.Trim();
        if (normalized.Length > maxLength)
        {
            throw new ArgumentOutOfRangeException(parameterName, $"Value must be {maxLength} characters or fewer.");
        }

        return normalized;
    }

    private static string? NormalizeOptional(string? value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var normalized = value.Trim();
        return normalized.Length <= maxLength ? normalized : normalized[..maxLength];
    }
}
