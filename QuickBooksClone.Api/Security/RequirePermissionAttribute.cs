namespace QuickBooksClone.Api.Security;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true, Inherited = true)]
public sealed class RequirePermissionAttribute : Attribute
{
    public RequirePermissionAttribute(string permission)
    {
        Permission = string.IsNullOrWhiteSpace(permission)
            ? throw new ArgumentException("Permission is required.", nameof(permission))
            : permission.Trim();
    }

    public string Permission { get; }
}
