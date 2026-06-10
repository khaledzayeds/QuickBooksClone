using Zayed.Core.Common;

namespace Zayed.Core.Modules;

public sealed class ModuleDefinition : EntityBase
{
    private ModuleDefinition()
    {
        Code = string.Empty;
        Name = string.Empty;
    }

    public ModuleDefinition(Guid id, string code, string name, string? description = null, bool isActive = true)
    {
        Id = id;
        Code = NormalizeRequired(code, nameof(code));
        Name = NormalizeRequired(name, nameof(name));
        Description = NormalizeOptional(description);
        IsActive = isActive;
    }

    public string Code { get; private set; }
    public string Name { get; private set; }
    public string? Description { get; private set; }
    public bool IsActive { get; private set; }

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
