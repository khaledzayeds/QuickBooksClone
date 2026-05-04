namespace QuickBooksClone.Api.Contracts.Setup;

public sealed record SetupStatusResponse(
    bool HasCompanySettings,
    bool HasAdminUser,
    bool IsInitialized,
    string? CompanyName,
    string? AdminUserName);

public sealed record InitializeCompanyRequest(
    string CompanyName,
    string Currency,
    string Country,
    string TimeZoneId,
    string DefaultLanguage,
    string? LegalName,
    string? Email,
    string? Phone,
    string AdminUserName,
    string AdminDisplayName,
    string? AdminEmail,
    string InitialAdminSecret);

public sealed record InitializeCompanyResponse(
    bool Initialized,
    string CompanyName,
    string AdminUserName,
    string AdminRoleKey);
