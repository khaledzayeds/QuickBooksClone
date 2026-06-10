using Zayed.Core.Common;

namespace Zayed.Core.Modules;

public sealed class MenuItemDefinition : EntityBase
{
    private MenuItemDefinition()
    {
        ModuleCode = string.Empty;
        TitleAr = string.Empty;
        TitleEn = string.Empty;
        Icon = string.Empty;
    }

    public MenuItemDefinition(
        Guid id,
        string moduleCode,
        Guid? parentId,
        string titleAr,
        string titleEn,
        string? route,
        string icon,
        int sortOrder,
        bool isActive = true)
    {
        Id = id;
        ModuleCode = NormalizeRequired(moduleCode, nameof(moduleCode));
        ParentId = parentId;
        TitleAr = NormalizeRequired(titleAr, nameof(titleAr));
        TitleEn = NormalizeRequired(titleEn, nameof(titleEn));
        Route = NormalizeOptional(route);
        Icon = string.IsNullOrWhiteSpace(icon) ? "circle" : icon.Trim();
        SortOrder = sortOrder;
        IsActive = isActive;
    }

    public string ModuleCode { get; private set; }
    public Guid? ParentId { get; private set; }
    public string TitleAr { get; private set; }
    public string TitleEn { get; private set; }
    public string? Route { get; private set; }
    public string Icon { get; private set; }
    public int SortOrder { get; private set; }
    public bool IsActive { get; private set; }

    public void UpdateDefinition(
        string moduleCode,
        Guid? parentId,
        string titleAr,
        string titleEn,
        string? route,
        string icon,
        int sortOrder,
        bool isActive = true)
    {
        ModuleCode = NormalizeRequired(moduleCode, nameof(moduleCode));
        ParentId = parentId;
        TitleAr = NormalizeRequired(titleAr, nameof(titleAr));
        TitleEn = NormalizeRequired(titleEn, nameof(titleEn));
        Route = NormalizeOptional(route);
        Icon = string.IsNullOrWhiteSpace(icon) ? "circle" : icon.Trim();
        SortOrder = sortOrder;
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
