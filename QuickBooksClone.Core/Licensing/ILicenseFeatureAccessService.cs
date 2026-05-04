namespace QuickBooksClone.Core.Licensing;

public sealed record LicenseFeatureAccessResult(
    bool Allowed,
    string Message,
    string? Edition = null,
    string? Status = null);

public interface ILicenseFeatureAccessService
{
    LicenseFeatureAccessResult CheckFeature(string feature);
}
