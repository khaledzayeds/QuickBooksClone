namespace QuickBooksClone.Core.Licensing;

public sealed record LicenseActivationRequest(
    string Serial,
    string DeviceFingerprint,
    string? AppVersion,
    string? CompanyName);

public sealed record LicenseActivationResponse(
    string LicensePackage,
    string Serial,
    string Edition,
    string Status,
    DateTimeOffset IssuedAt,
    DateTimeOffset? ExpiresAt);

public sealed record LicenseFeatureSet(
    bool LocalMode,
    bool LanMode,
    bool HostedMode,
    bool BackupRestore,
    bool DemoCompany,
    bool AdvancedInventory,
    bool Payroll);

public sealed record LicenseIssueOptions(
    string Serial,
    string CustomerName,
    string Edition,
    string Status,
    int MaxUsers,
    int MaxDevices,
    int OfflineGraceDays,
    LicenseFeatureSet Features,
    DateTimeOffset? ExpiresAt,
    string DeviceFingerprint,
    string? AppVersion);

public interface ILicensePackageSigningService
{
    string SignLicensePackage(LicenseIssueOptions options);
}

public interface ILicenseActivationService
{
    Task<LicenseActivationResponse> ActivateAsync(LicenseActivationRequest request, CancellationToken cancellationToken = default);
}
