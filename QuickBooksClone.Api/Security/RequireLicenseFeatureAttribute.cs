namespace QuickBooksClone.Api.Security;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true, Inherited = true)]
public sealed class RequireLicenseFeatureAttribute : Attribute
{
    public RequireLicenseFeatureAttribute(string feature)
    {
        Feature = feature;
    }

    public string Feature { get; }
}

public static class LicenseFeatureNames
{
    public const string LocalMode = "localMode";
    public const string LanMode = "lanMode";
    public const string HostedMode = "hostedMode";
    public const string BackupRestore = "backupRestore";
    public const string DemoCompany = "demoCompany";
    public const string AdvancedInventory = "advancedInventory";
    public const string Payroll = "payroll";
}
