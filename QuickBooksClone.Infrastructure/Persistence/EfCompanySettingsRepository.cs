using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Settings;

namespace QuickBooksClone.Infrastructure.Persistence;

public sealed class EfCompanySettingsRepository : ICompanySettingsRepository
{
    private readonly QuickBooksCloneDbContext _db;

    public EfCompanySettingsRepository(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    public Task<CompanySettings?> GetAsync(CancellationToken cancellationToken = default) =>
        _db.CompanySettings.AsSingleQuery().SingleOrDefaultAsync(cancellationToken);

    public async Task<CompanySettings> AddAsync(CompanySettings settings, CancellationToken cancellationToken = default)
    {
        _db.CompanySettings.Add(settings);
        await _db.SaveChangesAsync(cancellationToken);
        return settings;
    }

    public async Task<CompanySettings> UpdateAsync(
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
        CancellationToken cancellationToken = default)
    {
        var settings = await GetAsync(cancellationToken)
            ?? throw new InvalidOperationException("Company settings were not initialized.");

        settings.Update(
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
            defaultPurchaseTaxRate);

        await _db.SaveChangesAsync(cancellationToken);
        return settings;
    }
}
