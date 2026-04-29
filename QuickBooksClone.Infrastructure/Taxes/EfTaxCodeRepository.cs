using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Taxes;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Infrastructure.Taxes;

public sealed class EfTaxCodeRepository : ITaxCodeRepository
{
    private readonly QuickBooksCloneDbContext _dbContext;

    public EfTaxCodeRepository(QuickBooksCloneDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<TaxCodeListResult> SearchAsync(TaxCodeSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(1, search.Page);
        var pageSize = Math.Clamp(search.PageSize, 1, 200);
        var query = _dbContext.TaxCodes.AsNoTracking().AsQueryable();

        if (!search.IncludeInactive)
        {
            query = query.Where(taxCode => taxCode.IsActive);
        }

        if (search.Scope is TaxCodeScope scope)
        {
            query = query.Where(taxCode => taxCode.Scope == scope || taxCode.Scope == TaxCodeScope.Both);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var value = search.Search.Trim();
            query = query.Where(taxCode => taxCode.Code.Contains(value) || taxCode.Name.Contains(value));
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderBy(taxCode => taxCode.Code)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new TaxCodeListResult(items, totalCount, page, pageSize);
    }

    public Task<TaxCode?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        _dbContext.TaxCodes.SingleOrDefaultAsync(taxCode => taxCode.Id == id, cancellationToken);

    public Task<TaxCode?> GetByCodeAsync(string code, CancellationToken cancellationToken = default)
    {
        var normalized = code.Trim().ToUpperInvariant();
        return _dbContext.TaxCodes.SingleOrDefaultAsync(taxCode => taxCode.Code == normalized, cancellationToken);
    }

    public async Task<bool> CodeExistsAsync(string code, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        var normalized = code.Trim().ToUpperInvariant();
        return await _dbContext.TaxCodes.AnyAsync(
            taxCode => taxCode.Code == normalized && (!excludingId.HasValue || taxCode.Id != excludingId.Value),
            cancellationToken);
    }

    public async Task<TaxCode> AddAsync(TaxCode taxCode, CancellationToken cancellationToken = default)
    {
        _dbContext.TaxCodes.Add(taxCode);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return taxCode;
    }

    public async Task<TaxCode?> UpdateAsync(Guid id, string code, string name, TaxCodeScope scope, decimal ratePercent, Guid taxAccountId, string? description, CancellationToken cancellationToken = default)
    {
        var taxCode = await _dbContext.TaxCodes.SingleOrDefaultAsync(current => current.Id == id, cancellationToken);
        if (taxCode is null)
        {
            return null;
        }

        taxCode.Update(code, name, scope, ratePercent, taxAccountId, description);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return taxCode;
    }

    public async Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default)
    {
        var taxCode = await _dbContext.TaxCodes.SingleOrDefaultAsync(current => current.Id == id, cancellationToken);
        if (taxCode is null)
        {
            return false;
        }

        taxCode.SetActive(isActive);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }
}
