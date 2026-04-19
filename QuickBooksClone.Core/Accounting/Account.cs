using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Accounting;

public sealed class Account : EntityBase, ITenantEntity
{
    private Account()
    {
        CompanyId = Guid.Empty;
        Code = string.Empty;
        Name = string.Empty;
    }

    public Account(
        string code,
        string name,
        AccountType accountType,
        string? description = null,
        Guid? parentId = null,
        Guid? companyId = null)
    {
        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        Code = NormalizeRequired(code, nameof(code));
        Name = NormalizeRequired(name, nameof(name));
        AccountType = accountType;
        Description = NormalizeOptional(description);
        ParentId = parentId;
        IsActive = true;
    }

    public Guid CompanyId { get; }
    public string Code { get; private set; }
    public string Name { get; private set; }
    public AccountType AccountType { get; private set; }
    public string? Description { get; private set; }
    public Guid? ParentId { get; private set; }
    public bool IsActive { get; private set; }

    public void Update(string code, string name, AccountType accountType, string? description, Guid? parentId)
    {
        Code = NormalizeRequired(code, nameof(code));
        Name = NormalizeRequired(name, nameof(name));
        AccountType = accountType;
        Description = NormalizeOptional(description);
        ParentId = parentId;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void SetActive(bool isActive)
    {
        IsActive = isActive;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    private static string NormalizeRequired(string value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Value is required.", parameterName);
        }

        return value.Trim();
    }

    private static string? NormalizeOptional(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
