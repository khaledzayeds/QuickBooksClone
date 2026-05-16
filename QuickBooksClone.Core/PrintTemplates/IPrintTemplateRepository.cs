namespace QuickBooksClone.Core.PrintTemplates;

public interface IPrintTemplateRepository
{
    Task<IReadOnlyList<PrintTemplate>> ListAsync(string? documentType, CancellationToken cancellationToken = default);

    Task<PrintTemplate?> GetAsync(Guid id, CancellationToken cancellationToken = default);

    Task<PrintTemplate> AddAsync(PrintTemplate template, CancellationToken cancellationToken = default);

    Task<PrintTemplate> UpdateAsync(PrintTemplate template, CancellationToken cancellationToken = default);

    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
