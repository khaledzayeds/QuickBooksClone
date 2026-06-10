using Microsoft.EntityFrameworkCore;
using Zayed.Core.Companies;
using Zayed.Core.Modules;
using Zayed.Infrastructure.Persistence;

namespace Zayed.Infrastructure.Modules;

public sealed class CompanyModuleAccessService : ICompanyModuleAccessService
{
    private readonly ZayedDbContext _db;
    private readonly ICompanyRuntimeService _runtime;

    public CompanyModuleAccessService(ZayedDbContext db, ICompanyRuntimeService runtime)
    {
        _db = db;
        _runtime = runtime;
    }

    public async Task<CurrentCompanyModules> GetCurrentModulesAsync(CancellationToken cancellationToken = default)
    {
        var runtime = RequireActiveRuntime();
        var modules = await GetEnabledModulesAsync(cancellationToken);
        return new CurrentCompanyModules(runtime.BusinessType, modules);
    }

    public async Task<IReadOnlyList<string>> GetEnabledModulesAsync(CancellationToken cancellationToken = default)
    {
        var runtime = RequireActiveRuntime();
        await EnsureCompanyModulesAsync(runtime, cancellationToken);
        var companyId = runtime.CompanyId!.Value;

        return await _db.CompanyModules
            .Where(companyModule => companyModule.CompanyId == companyId && companyModule.IsEnabled)
            .Join(
                _db.Modules.Where(module => module.IsActive),
                companyModule => companyModule.ModuleId,
                module => module.Id,
                (_, module) => module.Code)
            .OrderBy(code => code)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> HasModuleAsync(string moduleCode, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(moduleCode))
        {
            return false;
        }

        var enabledModules = await GetEnabledModulesAsync(cancellationToken);
        return enabledModules.Contains(moduleCode.Trim(), StringComparer.OrdinalIgnoreCase);
    }

    public async Task RequireModuleAsync(string moduleCode, CancellationToken cancellationToken = default)
    {
        if (!await HasModuleAsync(moduleCode, cancellationToken))
        {
            throw new ModuleNotEnabledException("Module is not enabled for this company.");
        }
    }

    public async Task<IReadOnlyList<CompanyMenuItem>> GetCurrentMenuAsync(CancellationToken cancellationToken = default)
    {
        var enabledModules = await GetEnabledModulesAsync(cancellationToken);
        var enabled = enabledModules.ToHashSet(StringComparer.OrdinalIgnoreCase);

        var items = (await _db.MenuItems
            .Where(menuItem => menuItem.IsActive)
            .OrderBy(menuItem => menuItem.SortOrder)
            .ThenBy(menuItem => menuItem.TitleEn)
            .ToListAsync(cancellationToken))
            .Where(menuItem => enabled.Contains(menuItem.ModuleCode))
            .ToList();

        var childrenByParent = items
            .Where(item => item.ParentId is not null)
            .GroupBy(item => item.ParentId!.Value)
            .ToDictionary(group => group.Key, group => group.ToList());

        return items
            .Where(item => item.ParentId is null)
            .Select(item => ToDto(item, childrenByParent))
            .ToList();
    }

    private async Task EnsureCompanyModulesAsync(ActiveCompanyRuntime runtime, CancellationToken cancellationToken)
    {
        if (runtime.CompanyId is not Guid companyId)
        {
            throw new InvalidOperationException("No active company is open.");
        }

        await EnsureModuleDefinitionsAsync(cancellationToken);

        if (await _db.CompanyModules.AnyAsync(module => module.CompanyId == companyId, cancellationToken))
        {
            return;
        }

        var normalizedBusinessType = BusinessTypes.NormalizeOrDefault(runtime.BusinessType);
        var enabledCodes = ModuleSeedCatalog.DefaultsByBusinessType.TryGetValue(normalizedBusinessType, out var defaults)
            ? defaults
            : ModuleSeedCatalog.DefaultsByBusinessType[BusinessTypes.Retail];

        var modules = await _db.Modules
            .Where(module => enabledCodes.Contains(module.Code))
            .ToListAsync(cancellationToken);

        foreach (var module in modules)
        {
            _db.CompanyModules.Add(new CompanyModule(companyId, module.Id, isEnabled: true));
        }

        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task EnsureModuleDefinitionsAsync(CancellationToken cancellationToken)
    {
        var changed = false;

        foreach (var module in ModuleSeedCatalog.Modules)
        {
            if (!await _db.Modules.AnyAsync(current => current.Code == module.Code, cancellationToken))
            {
                _db.Modules.Add(module);
                changed = true;
            }
        }

        foreach (var defaults in ModuleSeedCatalog.DefaultsByBusinessType)
        {
            foreach (var moduleCode in defaults.Value)
            {
                var module = ModuleSeedCatalog.Modules.First(current => current.Code == moduleCode);
                if (!await _db.BusinessTypeModuleDefaults.AnyAsync(current =>
                    current.BusinessType == defaults.Key && current.ModuleId == module.Id,
                    cancellationToken))
                {
                    _db.BusinessTypeModuleDefaults.Add(new BusinessTypeModuleDefault(defaults.Key, module.Id, isEnabledByDefault: true));
                    changed = true;
                }
            }
        }

        foreach (var menuItem in ModuleSeedCatalog.MenuItems)
        {
            if (!await _db.MenuItems.AnyAsync(current => current.Id == menuItem.Id, cancellationToken))
            {
                _db.MenuItems.Add(menuItem);
                changed = true;
            }
        }

        if (changed)
        {
            await _db.SaveChangesAsync(cancellationToken);
        }
    }

    private ActiveCompanyRuntime RequireActiveRuntime()
    {
        var runtime = _runtime.Current;
        if (!runtime.IsActive || runtime.CompanyId is null)
        {
            throw new InvalidOperationException("No active company is open.");
        }

        return runtime;
    }

    private static CompanyMenuItem ToDto(MenuItemDefinition item, IReadOnlyDictionary<Guid, List<MenuItemDefinition>> childrenByParent)
    {
        var children = childrenByParent.TryGetValue(item.Id, out var childItems)
            ? childItems.Select(child => ToDto(child, childrenByParent)).ToList()
            : [];

        return new CompanyMenuItem(
            item.Id,
            item.ParentId,
            item.ModuleCode,
            item.TitleAr,
            item.TitleEn,
            item.Route,
            item.Icon,
            item.SortOrder,
            children);
    }
}

public sealed class ModuleNotEnabledException : InvalidOperationException
{
    public ModuleNotEnabledException(string message)
        : base(message)
    {
    }
}
