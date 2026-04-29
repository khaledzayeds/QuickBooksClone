using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Taxes;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Taxes;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/tax-codes")]
[RequirePermission("Settings.Manage")]
public sealed class TaxCodesController : ControllerBase
{
    private readonly ITaxCodeRepository _taxCodes;
    private readonly IAccountRepository _accounts;

    public TaxCodesController(ITaxCodeRepository taxCodes, IAccountRepository accounts)
    {
        _taxCodes = taxCodes;
        _accounts = accounts;
    }

    [HttpGet]
    [ProducesResponseType(typeof(TaxCodeListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<TaxCodeListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] TaxCodeScope? scope,
        [FromQuery] bool includeInactive = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        var result = await _taxCodes.SearchAsync(new TaxCodeSearch(search, scope, includeInactive, page, pageSize), cancellationToken);
        return Ok(new TaxCodeListResponse(result.Items.Select(ToDto).ToList(), result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(TaxCodeDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TaxCodeDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var taxCode = await _taxCodes.GetByIdAsync(id, cancellationToken);
        return taxCode is null ? NotFound() : Ok(ToDto(taxCode));
    }

    [HttpPost]
    [ProducesResponseType(typeof(TaxCodeDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<TaxCodeDto>> Create(CreateTaxCodeRequest request, CancellationToken cancellationToken = default)
    {
        if (!Enum.IsDefined(request.Scope))
        {
            return BadRequest("Invalid tax code scope.");
        }

        if (await _taxCodes.CodeExistsAsync(request.Code, null, cancellationToken))
        {
            return Conflict("Tax code already exists.");
        }

        var account = await _accounts.GetByIdAsync(request.TaxAccountId, cancellationToken);
        if (account is null || !account.IsActive)
        {
            return BadRequest("Tax account must exist and be active.");
        }

        try
        {
            var taxCode = new TaxCode(request.Code, request.Name, request.Scope, request.RatePercent, request.TaxAccountId, request.Description);
            await _taxCodes.AddAsync(taxCode, cancellationToken);
            return CreatedAtAction(nameof(Get), new { id = taxCode.Id }, ToDto(taxCode));
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(TaxCodeDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<TaxCodeDto>> Update(Guid id, UpdateTaxCodeRequest request, CancellationToken cancellationToken = default)
    {
        if (!Enum.IsDefined(request.Scope))
        {
            return BadRequest("Invalid tax code scope.");
        }

        if (await _taxCodes.CodeExistsAsync(request.Code, id, cancellationToken))
        {
            return Conflict("Tax code already exists.");
        }

        var account = await _accounts.GetByIdAsync(request.TaxAccountId, cancellationToken);
        if (account is null || !account.IsActive)
        {
            return BadRequest("Tax account must exist and be active.");
        }

        try
        {
            var taxCode = await _taxCodes.UpdateAsync(id, request.Code, request.Name, request.Scope, request.RatePercent, request.TaxAccountId, request.Description, cancellationToken);
            return taxCode is null ? NotFound() : Ok(ToDto(taxCode));
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPatch("{id:guid}/active")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetActive(Guid id, SetTaxCodeActiveRequest request, CancellationToken cancellationToken = default)
    {
        var updated = await _taxCodes.SetActiveAsync(id, request.IsActive, cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    private static TaxCodeDto ToDto(TaxCode taxCode) => new(
        taxCode.Id,
        taxCode.Code,
        taxCode.Name,
        taxCode.Scope,
        taxCode.RatePercent,
        taxCode.TaxAccountId,
        taxCode.Description,
        taxCode.IsActive);
}
