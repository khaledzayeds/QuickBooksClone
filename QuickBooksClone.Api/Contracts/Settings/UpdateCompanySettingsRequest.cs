using System.ComponentModel.DataAnnotations;
using QuickBooksClone.Core.Taxes;

namespace QuickBooksClone.Api.Contracts.Settings;

public sealed record UpdateCompanySettingsRequest(
    [Required, MaxLength(200)] string CompanyName,
    [MaxLength(200)] string? LegalName,
    [EmailAddress, MaxLength(250)] string? Email,
    [MaxLength(50)] string? Phone,
    [Required, MaxLength(10)] string Currency,
    [Required, MaxLength(120)] string Country,
    [Required, MaxLength(120)] string TimeZoneId,
    [Required, MaxLength(10)] string DefaultLanguage,
    [MaxLength(100)] string? TaxRegistrationNumber,
    [MaxLength(200)] string? AddressLine1,
    [MaxLength(200)] string? AddressLine2,
    [MaxLength(120)] string? City,
    [MaxLength(120)] string? Region,
    [MaxLength(40)] string? PostalCode,
    [Range(1, 12)] int FiscalYearStartMonth,
    [Range(1, 31)] int FiscalYearStartDay,
    [Range(0, 100)] decimal DefaultSalesTaxRate,
    [Range(0, 100)] decimal DefaultPurchaseTaxRate,
    bool TaxesEnabled,
    Guid? DefaultSalesTaxCodeId,
    Guid? DefaultPurchaseTaxCodeId,
    bool PricesIncludeTax,
    TaxRoundingMode TaxRoundingMode,
    Guid? DefaultSalesTaxPayableAccountId,
    Guid? DefaultPurchaseTaxReceivableAccountId);
