using Microsoft.Extensions.Configuration;
using QuickBooksClone.Core.Licensing;

namespace QuickBooksClone.Infrastructure.Licensing;

public sealed class ConfigurationLicenseActivationService : ILicenseActivationService
{
    private readonly IConfiguration _configuration;
    private readonly ILicensePackageSigningService _signingService;

    public ConfigurationLicenseActivationService(IConfiguration configuration, ILicensePackageSigningService signingService)
    {
        _configuration = configuration;
        _signingService = signingService;
    }

    public Task<LicenseActivationResponse> ActivateAsync(LicenseActivationRequest request, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();

        if (string.IsNullOrWhiteSpace(request.Serial))
        {
            throw new ArgumentException("Serial is required.", nameof(request));
        }

        if (string.IsNullOrWhiteSpace(request.DeviceFingerprint))
        {
            throw new ArgumentException("Device fingerprint is required.", nameof(request));
        }

        var licenseSection = FindLicenseSection(request.Serial);
        if (licenseSection is null)
        {
            throw new InvalidOperationException("Serial was not found or is not active.");
        }

        var edition = licenseSection.GetValue("Edition", "solo")!.ToLowerInvariant();
        var status = licenseSection.GetValue("Status", "active")!.ToLowerInvariant();
        var customerName = request.CompanyName
            ?? licenseSection.GetValue<string>("CustomerName")
            ?? "Customer";
        var expiresAtRaw = licenseSection.GetValue<string>("ExpiresAt");
        var expiresAt = DateTimeOffset.TryParse(expiresAtRaw, out var parsedExpiry) ? parsedExpiry : (DateTimeOffset?)null;
        var now = DateTimeOffset.UtcNow;

        if (expiresAt is not null && expiresAt <= now)
        {
            throw new InvalidOperationException("This license has expired.");
        }

        var defaults = DefaultsForEdition(edition);
        var options = new LicenseIssueOptions(
            request.Serial.Trim(),
            customerName,
            edition,
            status,
            licenseSection.GetValue("MaxUsers", defaults.MaxUsers),
            licenseSection.GetValue("MaxDevices", defaults.MaxDevices),
            licenseSection.GetValue("OfflineGraceDays", defaults.OfflineGraceDays),
            FeatureSetFromConfiguration(licenseSection.GetSection("Features"), defaults.Features),
            expiresAt,
            request.DeviceFingerprint.Trim(),
            request.AppVersion);

        var package = _signingService.SignLicensePackage(options);
        return Task.FromResult(new LicenseActivationResponse(
            package,
            options.Serial,
            options.Edition,
            options.Status,
            now,
            options.ExpiresAt));
    }

    private IConfigurationSection? FindLicenseSection(string serial)
    {
        var normalized = serial.Trim();
        var licenses = _configuration.GetSection("Licensing:Licenses").GetChildren();
        foreach (var section in licenses)
        {
            var configuredSerial = section.GetValue<string>("Serial");
            var status = section.GetValue("Status", "active");
            if (string.Equals(configuredSerial, normalized, StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(status, "blocked", StringComparison.OrdinalIgnoreCase))
            {
                return section;
            }
        }

        return null;
    }

    private static LicenseIssueOptions DefaultsForEdition(string edition)
    {
        return edition switch
        {
            "trial" => new LicenseIssueOptions(
                "",
                "Customer",
                "trial",
                "trial",
                1,
                1,
                7,
                new LicenseFeatureSet(true, false, false, false, true, false, false),
                null,
                "",
                null),
            "network" => new LicenseIssueOptions(
                "",
                "Customer",
                "network",
                "active",
                5,
                3,
                14,
                new LicenseFeatureSet(true, true, false, true, true, true, false),
                null,
                "",
                null),
            "hosted" => new LicenseIssueOptions(
                "",
                "Customer",
                "hosted",
                "active",
                10,
                10,
                3,
                new LicenseFeatureSet(false, false, true, true, true, true, true),
                null,
                "",
                null),
            _ => new LicenseIssueOptions(
                "",
                "Customer",
                "solo",
                "active",
                1,
                1,
                30,
                new LicenseFeatureSet(true, false, false, true, true, false, false),
                null,
                "",
                null)
        };
    }

    private static LicenseFeatureSet FeatureSetFromConfiguration(IConfigurationSection section, LicenseFeatureSet defaults)
    {
        return new LicenseFeatureSet(
            section.GetValue("LocalMode", defaults.LocalMode),
            section.GetValue("LanMode", defaults.LanMode),
            section.GetValue("HostedMode", defaults.HostedMode),
            section.GetValue("BackupRestore", defaults.BackupRestore),
            section.GetValue("DemoCompany", defaults.DemoCompany),
            section.GetValue("AdvancedInventory", defaults.AdvancedInventory),
            section.GetValue("Payroll", defaults.Payroll));
    }
}
