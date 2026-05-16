namespace QuickBooksClone.Core.PrintTemplates;

public sealed class PrintTemplate
{
    public PrintTemplate(
        Guid id,
        string name,
        string documentType,
        string pageSize,
        string jsonContent,
        bool isDefault,
        DateTime createdAt,
        DateTime updatedAt)
    {
        Id = id;
        Name = name;
        DocumentType = documentType;
        PageSize = pageSize;
        JsonContent = jsonContent;
        IsDefault = isDefault;
        CreatedAt = createdAt;
        UpdatedAt = updatedAt;
    }

    public Guid Id { get; init; }
    public string Name { get; init; }
    public string DocumentType { get; init; }
    public string PageSize { get; init; }
    public string JsonContent { get; init; }
    public bool IsDefault { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime UpdatedAt { get; init; }

    public static PrintTemplate Create(string name, string documentType, string pageSize, string jsonContent, bool isDefault)
    {
        var now = DateTime.UtcNow;
        return new PrintTemplate(
            Guid.NewGuid(),
            NormalizeRequired(name, "Template name"),
            NormalizeRequired(documentType, "Document type").ToLowerInvariant(),
            string.IsNullOrWhiteSpace(pageSize) ? "A4" : pageSize.Trim(),
            string.IsNullOrWhiteSpace(jsonContent) ? "{}" : jsonContent,
            isDefault,
            now,
            now);
    }

    public PrintTemplate WithUpdate(string name, string documentType, string pageSize, string jsonContent, bool isDefault)
    {
        return new PrintTemplate(
            Id,
            NormalizeRequired(name, "Template name"),
            NormalizeRequired(documentType, "Document type").ToLowerInvariant(),
            string.IsNullOrWhiteSpace(pageSize) ? PageSize : pageSize.Trim(),
            string.IsNullOrWhiteSpace(jsonContent) ? JsonContent : jsonContent,
            isDefault,
            CreatedAt,
            DateTime.UtcNow);
    }

    public PrintTemplate Clone(string? newName)
    {
        var now = DateTime.UtcNow;
        return new PrintTemplate(
            Guid.NewGuid(),
            string.IsNullOrWhiteSpace(newName) ? Name + " Copy" : newName.Trim(),
            DocumentType,
            PageSize,
            JsonContent,
            false,
            now,
            now);
    }

    private static string NormalizeRequired(string value, string label)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException(label + " is required.", nameof(value));
        }

        return value.Trim();
    }
}
