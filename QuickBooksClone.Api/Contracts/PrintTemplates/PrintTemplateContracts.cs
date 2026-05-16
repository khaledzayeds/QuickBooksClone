namespace QuickBooksClone.Api.Contracts.PrintTemplates;

public sealed record PrintTemplateResponse(
    Guid Id,
    string Name,
    string DocumentType,
    string PageSize,
    string JsonContent,
    bool IsDefault,
    DateTime CreatedAt,
    DateTime UpdatedAt);

public sealed record SavePrintTemplateRequest(
    string Name,
    string DocumentType,
    string PageSize,
    string JsonContent,
    bool IsDefault);

public sealed record ClonePrintTemplateRequest(string? Name);
