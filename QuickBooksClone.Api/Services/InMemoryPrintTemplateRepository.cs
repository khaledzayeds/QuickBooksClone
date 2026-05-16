using QuickBooksClone.Core.PrintTemplates;

namespace QuickBooksClone.Api.Services;

public sealed class InMemoryPrintTemplateRepository : IPrintTemplateRepository
{
    private static readonly List<PrintTemplate> Items = new();

    public Task<IReadOnlyList<PrintTemplate>> ListAsync(string? documentType, CancellationToken cancellationToken = default)
    {
        IEnumerable<PrintTemplate> query = Items;
        if (!string.IsNullOrWhiteSpace(documentType))
        {
            query = query.Where(item => item.DocumentType.Equals(documentType.Trim(), StringComparison.OrdinalIgnoreCase));
        }

        var result = query
            .OrderBy(item => item.DocumentType)
            .ThenByDescending(item => item.IsDefault)
            .ThenBy(item => item.Name)
            .ToList();

        return Task.FromResult<IReadOnlyList<PrintTemplate>>(result);
    }

    public Task<PrintTemplate?> GetAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Items.FirstOrDefault(item => item.Id == id));
    }

    public Task<PrintTemplate> AddAsync(PrintTemplate template, CancellationToken cancellationToken = default)
    {
        if (template.IsDefault)
        {
            ClearDefault(template.DocumentType);
        }

        Items.Add(template);
        return Task.FromResult(template);
    }

    public Task<PrintTemplate> UpdateAsync(PrintTemplate template, CancellationToken cancellationToken = default)
    {
        var index = Items.FindIndex(item => item.Id == template.Id);
        if (index < 0)
        {
            throw new KeyNotFoundException("Print template was not found.");
        }

        if (template.IsDefault)
        {
            ClearDefault(template.DocumentType);
        }

        index = Items.FindIndex(item => item.Id == template.Id);
        Items[index] = template;
        return Task.FromResult(template);
    }

    public Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        Items.RemoveAll(item => item.Id == id);
        return Task.CompletedTask;
    }

    private static void ClearDefault(string documentType)
    {
        for (var index = 0; index < Items.Count; index++)
        {
            var item = Items[index];
            if (item.DocumentType.Equals(documentType, StringComparison.OrdinalIgnoreCase))
            {
                Items[index] = item.WithUpdate(item.Name, item.DocumentType, item.PageSize, item.JsonContent, false);
            }
        }
    }
}
