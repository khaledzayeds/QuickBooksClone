namespace QuickBooksClone.Core.Companies;

public sealed record ActiveCompanyRuntime(
    Guid? CompanyId,
    string? CompanyName,
    string DatabasePath,
    bool IsActive,
    DateTimeOffset? OpenedAtUtc);
