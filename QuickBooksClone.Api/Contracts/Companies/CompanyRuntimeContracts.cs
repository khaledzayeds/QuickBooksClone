namespace QuickBooksClone.Api.Contracts.Companies;

public sealed record ActiveCompanyRuntimeResponse(
    Guid? CompanyId,
    string? CompanyName,
    string DatabasePath,
    bool IsActive,
    DateTimeOffset? OpenedAtUtc);

public sealed record OpenCompanyRequest(
    Guid CompanyId,
    string CompanyName,
    string DatabasePath);
