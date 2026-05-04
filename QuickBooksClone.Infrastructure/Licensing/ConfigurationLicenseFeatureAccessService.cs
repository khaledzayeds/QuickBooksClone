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

        var edition = section.GetValue("Edition", "unknown");
        var status = section.GetValue("Status", "inactive");
        if (string.Equals(status, "blocked", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(status, "inactive", StringComparison.OrdinalIgnoreCase))
        {
            return new LicenseFeatureAccessResult(false, $"Backend license is {status}.", edition, status);
        }

        var expiresAtRaw = section.GetValue<string>("ExpiresAt");
        if (DateTimeOffset.TryParse(expiresAtRaw, out var expiresAt) && expiresAt <= DateTimeOffset.UtcNow)
        {
            return new LicenseFeatureAccessResult(false, "Backend license has expired.", edition, "expired");
        }

        var features = section.GetSection("Features");
        var allowed = features.GetValue<bool?>(NormalizeFeatureKey(feature)) ?? false;
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
}
