using Microsoft.Extensions.Configuration;
using QuickBooksClone.Core.Licensing;

namespace QuickBooksClone.Infrastructure.Licensing;

public sealed class ConfigurationLicenseFeatureAccessService : ILicenseFeatureAccessService
{
    private readonly IConfiguration _configuration;

    public ConfigurationLicenseFeatureAccessService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public LicenseFeatureAccessResult CheckFeature(string feature)
    {
        var section = _configuration.GetSection("Licensing:CurrentLicense");
        if (!section.Exists())
        {
            return new LicenseFeatureAccessResult(
                false,
                "No backend current license is configured. Configure Licensing:CurrentLicense for API feature enforcement.");
        }

        var edition = ReadString(section, "Edition", "unknown");
        var status = ReadString(section, "Status", "inactive");
        if (string.Equals(status, "blocked", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(status, "inactive", StringComparison.OrdinalIgnoreCase))
        {
            return new LicenseFeatureAccessResult(false, $"Backend license is {status}.", edition, status);
        }

        var expiresAtRaw = ReadNullableString(section, "ExpiresAt");
        if (DateTimeOffset.TryParse(expiresAtRaw, out var expiresAt) && expiresAt <= DateTimeOffset.UtcNow)
        {
            return new LicenseFeatureAccessResult(false, "Backend license has expired.", edition, "expired");
        }

        var features = section.GetSection("Features");
        var allowed = ReadNullableBool(features, NormalizeFeatureKey(feature)) ?? false;
        return allowed
            ? new LicenseFeatureAccessResult(true, "Allowed.", edition, status)
            : new LicenseFeatureAccessResult(false, $"Feature '{feature}' is not included in the backend {edition} license.", edition, status);
    }

    private static string NormalizeFeatureKey(string feature)
    {
        return feature switch
        {
            "localMode" => "LocalMode",
            "lanMode" => "LanMode",
            "hostedMode" => "HostedMode",
            "backupRestore" => "BackupRestore",
            "demoCompany" => "DemoCompany",
            "advancedInventory" => "AdvancedInventory",
            "payroll" => "Payroll",
            _ => feature
        };
    }

    private static string ReadString(IConfiguration section, string key, string fallback)
    {
        var value = section[key];
        return string.IsNullOrWhiteSpace(value) ? fallback : value.Trim();
    }

    private static string? ReadNullableString(IConfiguration section, string key)
    {
        var value = section[key];
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    private static bool? ReadNullableBool(IConfiguration section, string key)
    {
        return bool.TryParse(section[key], out var value) ? value : null;
    }
}
