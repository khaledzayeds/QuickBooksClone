namespace QuickBooksClone.Api.Security;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, Inherited = true)]
public sealed class RequireAuthenticatedAttribute : Attribute
{
}
