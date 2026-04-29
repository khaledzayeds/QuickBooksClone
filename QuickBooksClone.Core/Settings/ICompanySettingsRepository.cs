using QuickBooksClone.Core.Taxes;

namespace QuickBooksClone.Core.Settings;

public interface ICompanySettingsRepository
{
    Task<CompanySettings?> GetAsync(CancellationToken cancellationToken = default);
    Task<CompanySettings> AddAsync(CompanySettings settings, CancellationToken cancellationToken = default);
    Task<CompanySettings> UpdateAsync(
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
        Guid? defaultPurchaseTaxReceivableAccountId,
        CancellationToken cancellationToken = default);
}
