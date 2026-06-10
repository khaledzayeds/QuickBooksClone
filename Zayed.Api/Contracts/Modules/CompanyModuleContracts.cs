namespace Zayed.Api.Contracts.Modules;

public sealed record CurrentCompanyModulesResponse(
    string BusinessType,
    IReadOnlyList<string> EnabledModules);

public sealed record MenuItemResponse(
    Guid Id,
    Guid? ParentId,
    string ModuleCode,
    string TitleAr,
    string TitleEn,
    string? Route,
    string Icon,
    int SortOrder,
    IReadOnlyList<MenuItemResponse> Children);

public sealed record HotelModuleStatusResponse(
    string ModuleCode,
    bool Enabled,
    string Message);
