namespace QuickBooksClone.Core.Taxes;

public interface ITaxCodeRepository
{
    Task<TaxCodeListResult> SearchAsync(TaxCodeSearch search, CancellationToken cancellationToken = default);
    Task<TaxCode?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<TaxCode?> GetByCodeAsync(string code, CancellationToken cancellationToken = default);
    Task<bool> CodeExistsAsync(string code, Guid? excludingId = null, CancellationToken cancellationToken = default);
    Task<TaxCode> AddAsync(TaxCode taxCode, CancellationToken cancellationToken = default);
    Task<TaxCode?> UpdateAsync(Guid id, string code, string name, TaxCodeScope scope, decimal ratePercent, Guid taxAccountId, string? description, CancellationToken cancellationToken = default);
    Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default);
}

public sealed record TaxCodeSearch(string? Search, TaxCodeScope? Scope, bool IncludeInactive = false, int Page = 1, int PageSize = 50);

public sealed record TaxCodeListResult(IReadOnlyList<TaxCode> Items, int TotalCount, int Page, int PageSize);
