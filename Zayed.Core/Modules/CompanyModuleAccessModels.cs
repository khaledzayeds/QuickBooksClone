namespace Zayed.Core.Modules;

public sealed record CurrentCompanyModules(
    string BusinessType,
    IReadOnlyList<string> EnabledModules);

public sealed record CompanyMenuItem(
    Guid Id,
    Guid? ParentId,
    string ModuleCode,
    string TitleAr,
    string TitleEn,
    string? Route,
    string Icon,
    int SortOrder,
    IReadOnlyList<CompanyMenuItem> Children);

public interface ICompanyModuleAccessService
{
    Task<CurrentCompanyModules> GetCurrentModulesAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<string>> GetEnabledModulesAsync(CancellationToken cancellationToken = default);

    Task<bool> HasModuleAsync(string moduleCode, CancellationToken cancellationToken = default);

    Task RequireModuleAsync(string moduleCode, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CompanyMenuItem>> GetCurrentMenuAsync(CancellationToken cancellationToken = default);
}
