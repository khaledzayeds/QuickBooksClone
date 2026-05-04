namespace QuickBooksClone.Api.Contracts.Licensing;

public sealed record ActivateLicenseRequest(
    string Serial,
    string DeviceFingerprint,
    string? AppVersion,
    string? CompanyName);

public sealed record ActivateLicenseResponse(
    string LicensePackage,
    string Serial,
    string Edition,
    string Status,
    DateTimeOffset IssuedAt,
    DateTimeOffset? ExpiresAt);
