using Microsoft.AspNetCore.Mvc;
using Zayed.Api.Contracts.Modules;
using Zayed.Core.Modules;

namespace Zayed.Api.Controllers;

[ApiController]
[Route("api/navigation")]
public sealed class NavigationController : ControllerBase
{
    private readonly ICompanyModuleAccessService _modules;

    public NavigationController(ICompanyModuleAccessService modules)
    {
        _modules = modules;
    }

    [HttpGet("menu")]
    [ProducesResponseType(typeof(IReadOnlyList<MenuItemResponse>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<MenuItemResponse>>> GetMenu(CancellationToken cancellationToken = default)
    {
        var menu = await _modules.GetCurrentMenuAsync(cancellationToken);
        return Ok(menu.Select(ToResponse).ToList());
    }

    private static MenuItemResponse ToResponse(CompanyMenuItem item)
    {
        return new MenuItemResponse(
            item.Id,
            item.ParentId,
            item.ModuleCode,
            item.TitleAr,
            item.TitleEn,
            item.Route,
            item.Icon,
            item.SortOrder,
            item.Children.Select(ToResponse).ToList());
    }
}
