namespace Zayed.Core.Companies;

public sealed record ActiveCompanyRuntime(
    Guid? CompanyId,
    string? CompanyName,
    string BusinessType,
    string DatabasePath,
    bool IsActive,
    DateTimeOffset? OpenedAtUtc,
    bool IsSetupInitialized = false);
