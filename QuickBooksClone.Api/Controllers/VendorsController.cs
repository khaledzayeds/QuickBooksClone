using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Vendors;
using QuickBooksClone.Core.OpeningBalances;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/vendors")]
public sealed class VendorsController : ControllerBase
{
    private readonly IVendorRepository _vendors;
    private readonly IOpeningBalancePostingService _openingBalances;

    public VendorsController(IVendorRepository vendors, IOpeningBalancePostingService openingBalances)
    {
        _vendors = vendors;
        _openingBalances = openingBalances;
    }

    [HttpGet]
    [ProducesResponseType(typeof(VendorListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<VendorListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] bool includeInactive = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _vendors.SearchAsync(new VendorSearch(search, includeInactive, page, pageSize), cancellationToken);

        return Ok(new VendorListResponse(
            result.Items.Select(ToDto).ToList(),
            result.TotalCount,
            result.Page,
            result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(VendorDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<VendorDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var vendor = await _vendors.GetByIdAsync(id, cancellationToken);
        return vendor is null ? NotFound() : Ok(ToDto(vendor));
    }

    [HttpPost]
    [ProducesResponseType(typeof(VendorDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<VendorDto>> Create(CreateVendorRequest request, CancellationToken cancellationToken = default)
    {
        var duplicateValidation = await ValidateUniqueVendorAsync(request.DisplayName, request.Email, null, cancellationToken);
        if (duplicateValidation is not null)
        {
            return Conflict(duplicateValidation);
        }

        var vendor = new Vendor(
            request.DisplayName,
            request.CompanyName,
            request.Email,
            request.Phone,
            request.Currency ?? "EGP",
            request.OpeningBalance);

        await _vendors.AddAsync(vendor, cancellationToken);
        var openingBalanceResult = await _openingBalances.PostVendorOpeningBalanceAsync(vendor, cancellationToken);
        if (!openingBalanceResult.Succeeded)
        {
            return BadRequest(openingBalanceResult.ErrorMessage);
        }

        return CreatedAtAction(nameof(Get), new { id = vendor.Id }, ToDto(vendor));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(VendorDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<VendorDto>> Update(Guid id, UpdateVendorRequest request, CancellationToken cancellationToken = default)
    {
        var duplicateValidation = await ValidateUniqueVendorAsync(request.DisplayName, request.Email, id, cancellationToken);
        if (duplicateValidation is not null)
        {
            return Conflict(duplicateValidation);
        }

        var vendor = await _vendors.UpdateAsync(
            id,
            request.DisplayName,
            request.CompanyName,
            request.Email,
            request.Phone,
            request.Currency ?? "EGP",
            cancellationToken);

        return vendor is null ? NotFound() : Ok(ToDto(vendor));
    }

    [HttpPatch("{id:guid}/active")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetActive(Guid id, SetVendorActiveRequest request, CancellationToken cancellationToken = default)
    {
        var updated = await _vendors.SetActiveAsync(id, request.IsActive, cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    private async Task<string?> ValidateUniqueVendorAsync(
        string displayName,
        string? email,
        Guid? excludingId,
        CancellationToken cancellationToken)
    {
        if (await _vendors.DisplayNameExistsAsync(displayName, excludingId, cancellationToken))
        {
            return "Vendor display name already exists.";
        }

        if (!string.IsNullOrWhiteSpace(email) && await _vendors.EmailExistsAsync(email, excludingId, cancellationToken))
        {
            return "Vendor email already exists.";
        }

        return null;
    }

    private static VendorDto ToDto(Vendor vendor)
    {
        return new VendorDto(
            vendor.Id,
            vendor.DisplayName,
            vendor.CompanyName,
            vendor.Email,
            vendor.Phone,
            vendor.Currency,
            vendor.Balance,
            vendor.IsActive);
    }
}
