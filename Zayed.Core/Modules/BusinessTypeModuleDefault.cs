using Zayed.Core.Common;

namespace Zayed.Core.Modules;

public sealed class BusinessTypeModuleDefault : EntityBase
{
    private BusinessTypeModuleDefault()
    {
        BusinessType = string.Empty;
    }

    public BusinessTypeModuleDefault(string businessType, Guid moduleId, bool isEnabledByDefault)
    {
        BusinessType = NormalizeRequired(businessType, nameof(businessType));
        ModuleId = moduleId;
        IsEnabledByDefault = isEnabledByDefault;
    }

    public string BusinessType { get; private set; }
    public Guid ModuleId { get; private set; }
    public bool IsEnabledByDefault { get; private set; }

    private static string NormalizeRequired(string value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Value is required.", parameterName);
        }

        return value.Trim();
    }
}
