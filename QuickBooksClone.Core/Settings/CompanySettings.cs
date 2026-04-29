using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.Taxes;

namespace QuickBooksClone.Core.Settings;

public sealed class CompanySettings : EntityBase, ITenantEntity
{
    public CompanySettings()
    {
        CompanyId = Guid.Empty;
        CompanyName = string.Empty;
        Currency = string.Empty;
        Country = string.Empty;
        TimeZoneId = string.Empty;
        DefaultLanguage = string.Empty;
    }

    public CompanySettings(
        string companyName,
        string currency,
        string country,
        string timeZoneId,
        string defaultLanguage,
        string? legalName = null,
        string? email = null,
        string? phone = null,
        string? taxRegistrationNumber = null,
        string? addressLine1 = null,
        string? addressLine2 = null,
        string? city = null,
        string? region = null,
        string? postalCode = null,
        int fiscalYearStartMonth = 1,
        int fiscalYearStartDay = 1,
        decimal defaultSalesTaxRate = 0,
        decimal defaultPurchaseTaxRate = 0,
        bool taxesEnabled = false,
        Guid? defaultSalesTaxCodeId = null,
        Guid? defaultPurchaseTaxCodeId = null,
        bool pricesIncludeTax = false,
        TaxRoundingMode taxRoundingMode = TaxRoundingMode.PerLine,
        Guid? defaultSalesTaxPayableAccountId = null,
        Guid? defaultPurchaseTaxReceivableAccountId = null,
        Guid? companyId = null)
    {
        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        Update(
            companyName,
            currency,
            country,
            timeZoneId,
            defaultLanguage,
            legalName,
            email,
            phone,
            taxRegistrationNumber,
            addressLine1,
            addressLine2,
            city,
            region,
            postalCode,
            fiscalYearStartMonth,
            fiscalYearStartDay,
            defaultSalesTaxRate,
            defaultPurchaseTaxRate,
            taxesEnabled,
            defaultSalesTaxCodeId,
            defaultPurchaseTaxCodeId,
            pricesIncludeTax,
            taxRoundingMode,
            defaultSalesTaxPayableAccountId,
            defaultPurchaseTaxReceivableAccountId);
    }

    public Guid CompanyId { get; }
    public string CompanyName { get; private set; } = string.Empty;
    public string? LegalName { get; private set; }
    public string? Email { get; private set; }
    public string? Phone { get; private set; }
    public string Currency { get; private set; } = string.Empty;
    public string Country { get; private set; } = string.Empty;
    public string TimeZoneId { get; private set; } = string.Empty;
    public string DefaultLanguage { get; private set; } = string.Empty;
    public string? TaxRegistrationNumber { get; private set; }
    public string? AddressLine1 { get; private set; }
    public string? AddressLine2 { get; private set; }
    public string? City { get; private set; }
    public string? Region { get; private set; }
    public string? PostalCode { get; private set; }
    public int FiscalYearStartMonth { get; private set; }
    public int FiscalYearStartDay { get; private set; }
    public decimal DefaultSalesTaxRate { get; private set; }
    public decimal DefaultPurchaseTaxRate { get; private set; }
    public bool TaxesEnabled { get; private set; }
    public Guid? DefaultSalesTaxCodeId { get; private set; }
    public Guid? DefaultPurchaseTaxCodeId { get; private set; }
    public bool PricesIncludeTax { get; private set; }
    public TaxRoundingMode TaxRoundingMode { get; private set; }
    public Guid? DefaultSalesTaxPayableAccountId { get; private set; }
    public Guid? DefaultPurchaseTaxReceivableAccountId { get; private set; }

    public void Update(
        string companyName,
        string currency,
        string country,
        string timeZoneId,
        string defaultLanguage,
        string? legalName,
        string? email,
        string? phone,
        string? taxRegistrationNumber,
        string? addressLine1,
        string? addressLine2,
        string? city,
        string? region,
        string? postalCode,
        int fiscalYearStartMonth,
        int fiscalYearStartDay,
        decimal defaultSalesTaxRate,
        decimal defaultPurchaseTaxRate,
        bool taxesEnabled,
        Guid? defaultSalesTaxCodeId,
        Guid? defaultPurchaseTaxCodeId,
        bool pricesIncludeTax,
        TaxRoundingMode taxRoundingMode,
        Guid? defaultSalesTaxPayableAccountId,
        Guid? defaultPurchaseTaxReceivableAccountId)
    {
        CompanyName = NormalizeRequired(companyName, nameof(companyName));
        Currency = NormalizeRequired(currency, nameof(currency)).ToUpperInvariant();
        Country = NormalizeRequired(country, nameof(country));
        TimeZoneId = NormalizeRequired(timeZoneId, nameof(timeZoneId));
        DefaultLanguage = NormalizeRequired(defaultLanguage, nameof(defaultLanguage)).ToLowerInvariant();
        LegalName = NormalizeOptional(legalName);
        Email = NormalizeOptional(email);
        Phone = NormalizeOptional(phone);
        TaxRegistrationNumber = NormalizeOptional(taxRegistrationNumber);
        AddressLine1 = NormalizeOptional(addressLine1);
        AddressLine2 = NormalizeOptional(addressLine2);
        City = NormalizeOptional(city);
        Region = NormalizeOptional(region);
        PostalCode = NormalizeOptional(postalCode);

        if (fiscalYearStartMonth is < 1 or > 12)
        {
            throw new ArgumentOutOfRangeException(nameof(fiscalYearStartMonth), "Fiscal year start month must be between 1 and 12.");
        }

        if (fiscalYearStartDay is < 1 or > 31)
        {
            throw new ArgumentOutOfRangeException(nameof(fiscalYearStartDay), "Fiscal year start day must be between 1 and 31.");
        }

        if (defaultSalesTaxRate < 0 || defaultSalesTaxRate > 100)
        {
            throw new ArgumentOutOfRangeException(nameof(defaultSalesTaxRate), "Default sales tax rate must be between 0 and 100.");
        }

        if (defaultPurchaseTaxRate < 0 || defaultPurchaseTaxRate > 100)
        {
            throw new ArgumentOutOfRangeException(nameof(defaultPurchaseTaxRate), "Default purchase tax rate must be between 0 and 100.");
        }

        FiscalYearStartMonth = fiscalYearStartMonth;
        FiscalYearStartDay = fiscalYearStartDay;
        DefaultSalesTaxRate = defaultSalesTaxRate;
        DefaultPurchaseTaxRate = defaultPurchaseTaxRate;
        TaxesEnabled = taxesEnabled;
        DefaultSalesTaxCodeId = defaultSalesTaxCodeId == Guid.Empty ? null : defaultSalesTaxCodeId;
        DefaultPurchaseTaxCodeId = defaultPurchaseTaxCodeId == Guid.Empty ? null : defaultPurchaseTaxCodeId;
        PricesIncludeTax = pricesIncludeTax;
        TaxRoundingMode = Enum.IsDefined(taxRoundingMode) ? taxRoundingMode : TaxRoundingMode.PerLine;
        DefaultSalesTaxPayableAccountId = defaultSalesTaxPayableAccountId == Guid.Empty ? null : defaultSalesTaxPayableAccountId;
        DefaultPurchaseTaxReceivableAccountId = defaultPurchaseTaxReceivableAccountId == Guid.Empty ? null : defaultPurchaseTaxReceivableAccountId;
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
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Trim();
    }
}
