namespace QuickBooksClone.Api.Contracts.Settings;

public sealed record CompanySettingsDto(
    Guid Id,
    Guid CompanyId,
    string CompanyName,
    string? LegalName,
    string? Email,
    string? Phone,
    string Currency,
    string Country,
    string TimeZoneId,
    string DefaultLanguage,
    string? TaxRegistrationNumber,
    string? AddressLine1,
    string? AddressLine2,
    string? City,
    string? Region,
    string? PostalCode,
    int FiscalYearStartMonth,
    int FiscalYearStartDay,
    decimal DefaultSalesTaxRate,
    decimal DefaultPurchaseTaxRate);
