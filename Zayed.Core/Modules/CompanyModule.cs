using Zayed.Core.Common;

namespace Zayed.Core.Modules;

public sealed class CompanyModule : EntityBase
{
    private CompanyModule()
    {
        CompanyId = Guid.Empty;
    }

    public CompanyModule(Guid companyId, Guid moduleId, bool isEnabled)
    {
        if (companyId == Guid.Empty)
        {
            throw new ArgumentException("Company id is required.", nameof(companyId));
        }

        CompanyId = companyId;
        ModuleId = moduleId;
        IsEnabled = isEnabled;
    }

    public Guid CompanyId { get; private set; }
    public Guid ModuleId { get; private set; }
    public bool IsEnabled { get; private set; }

    public void SetEnabled(bool isEnabled)
    {
        IsEnabled = isEnabled;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
