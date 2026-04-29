using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Contracts.Estimates;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Estimates;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Core.Taxes;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/estimates")]
[RequirePermission("Sales.Estimate.Manage")]
public sealed class EstimatesController : ControllerBase
{
    private readonly IEstimateRepository _estimates;
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly IDocumentNumberService _documentNumbers;
    private readonly ICompanySettingsRepository _companySettings;
    private readonly ITaxCodeRepository _taxCodes;

    public EstimatesController(
        IEstimateRepository estimates,
        ICustomerRepository customers,
        IItemRepository items,
        IDocumentNumberService documentNumbers,
        ICompanySettingsRepository companySettings,
        ITaxCodeRepository taxCodes)
    {
        _estimates = estimates;
        _customers = customers;
        _items = items;
        _documentNumbers = documentNumbers;
        _companySettings = companySettings;
        _taxCodes = taxCodes;
    }

    [HttpGet]
    [ProducesResponseType(typeof(EstimateListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<EstimateListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] Guid? customerId,
        [FromQuery] bool includeClosed = false,
        [FromQuery] bool includeCancelled = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _estimates.SearchAsync(new EstimateSearch(search, customerId, includeClosed, includeCancelled, page, pageSize), cancellationToken);
        var items = new List<EstimateDto>();
        foreach (var estimate in result.Items)
        {
            items.Add(await ToDtoAsync(estimate, cancellationToken));
        }

        return Ok(new EstimateListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(EstimateDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<EstimateDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var estimate = await _estimates.GetByIdAsync(id, cancellationToken);
        return estimate is null ? NotFound() : Ok(await ToDtoAsync(estimate, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(EstimateDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<EstimateDto>> Create(CreateEstimateRequest request, CancellationToken cancellationToken = default)
    {
        var saveMode = request.SaveMode == 0 ? EstimateSaveMode.SaveAsSent : request.SaveMode;
        if (!Enum.IsDefined(saveMode))
        {
            return BadRequest("Invalid estimate save mode.");
        }

        var customer = await _customers.GetByIdAsync(request.CustomerId, cancellationToken);
        if (customer is null)
        {
            return BadRequest("Customer does not exist.");
        }

        if (!customer.IsActive)
        {
            return BadRequest("Cannot create an estimate for an inactive customer.");
        }

        if (request.Lines.Count == 0)
        {
            return BadRequest("Estimate must have at least one line.");
        }

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.Estimate, cancellationToken);
        var taxSettings = await _companySettings.GetAsync(cancellationToken);
        var estimate = new Estimate(request.CustomerId, request.EstimateDate, request.ExpirationDate, allocation.DocumentNo);
        estimate.SetSyncIdentity(allocation.DeviceId, allocation.DocumentNo);

        foreach (var line in request.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return BadRequest($"Item does not exist: {line.ItemId}");
            }

            if (!item.IsActive)
            {
                return BadRequest($"Cannot use inactive item on an estimate: {item.Name}");
            }

            var unitPrice = line.UnitPrice > 0 ? line.UnitPrice : item.SalesPrice;
            var description = string.IsNullOrWhiteSpace(line.Description) ? item.Name : line.Description;
            TaxLineCalculation tax;
            try
            {
                tax = await ResolveSalesTaxAsync(line.TaxCodeId, taxSettings, unitPrice, line.Quantity, cancellationToken);
            }
            catch (InvalidOperationException exception)
            {
                return BadRequest(exception.Message);
            }

            estimate.AddLine(new EstimateLine(item.Id, description, line.Quantity, tax.NetUnitPrice, tax.TaxCodeId, tax.RatePercent, tax.TaxAmount));
        }

        await _estimates.AddAsync(estimate, cancellationToken);

        if (saveMode == EstimateSaveMode.SaveAsSent)
        {
            await _estimates.MarkSentAsync(estimate.Id, cancellationToken);
        }

        var saved = await _estimates.GetByIdAsync(estimate.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = estimate.Id }, await ToDtoAsync(saved!, cancellationToken));
    }

    [HttpPost("{id:guid}/send")]
    public async Task<ActionResult<EstimateDto>> Send(Guid id, CancellationToken cancellationToken = default)
    {
        var estimate = await _estimates.GetByIdAsync(id, cancellationToken);
        if (estimate is null)
        {
            return NotFound();
        }

        try
        {
            await _estimates.MarkSentAsync(id, cancellationToken);
            var updated = await _estimates.GetByIdAsync(id, cancellationToken);
            return Ok(await ToDtoAsync(updated!, cancellationToken));
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPost("{id:guid}/accept")]
    public async Task<ActionResult<EstimateDto>> Accept(Guid id, CancellationToken cancellationToken = default)
    {
        var estimate = await _estimates.GetByIdAsync(id, cancellationToken);
        if (estimate is null)
        {
            return NotFound();
        }

        try
        {
            await _estimates.AcceptAsync(id, cancellationToken);
            var updated = await _estimates.GetByIdAsync(id, cancellationToken);
            return Ok(await ToDtoAsync(updated!, cancellationToken));
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPost("{id:guid}/decline")]
    public async Task<ActionResult<EstimateDto>> Decline(Guid id, CancellationToken cancellationToken = default)
    {
        var estimate = await _estimates.GetByIdAsync(id, cancellationToken);
        if (estimate is null)
        {
            return NotFound();
        }

        try
        {
            await _estimates.DeclineAsync(id, cancellationToken);
            var updated = await _estimates.GetByIdAsync(id, cancellationToken);
            return Ok(await ToDtoAsync(updated!, cancellationToken));
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPatch("{id:guid}/cancel")]
    public async Task<ActionResult<EstimateDto>> Cancel(Guid id, CancellationToken cancellationToken = default)
    {
        var estimate = await _estimates.GetByIdAsync(id, cancellationToken);
        if (estimate is null)
        {
            return NotFound();
        }

        try
        {
            await _estimates.CancelAsync(id, cancellationToken);
            var updated = await _estimates.GetByIdAsync(id, cancellationToken);
            return Ok(await ToDtoAsync(updated!, cancellationToken));
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    private async Task<EstimateDto> ToDtoAsync(Estimate estimate, CancellationToken cancellationToken)
    {
        var customer = await _customers.GetByIdAsync(estimate.CustomerId, cancellationToken);
        return new EstimateDto(
            estimate.Id,
            estimate.EstimateNumber,
            estimate.CustomerId,
            customer?.DisplayName,
            estimate.EstimateDate,
            estimate.ExpirationDate,
            estimate.Status,
            estimate.Subtotal,
            estimate.TaxAmount,
            estimate.TotalAmount,
            estimate.SentAt,
            estimate.AcceptedAt,
            estimate.DeclinedAt,
            estimate.CancelledAt,
            estimate.Lines.Select(line => new EstimateLineDto(
                line.Id,
                line.ItemId,
                line.Description,
                line.Quantity,
                line.UnitPrice,
                line.TaxCodeId,
                line.TaxRatePercent,
                line.TaxAmount,
                line.LineTotal)).ToList());
    }

    private async Task<TaxLineCalculation> ResolveSalesTaxAsync(
        Guid? requestedTaxCodeId,
        QuickBooksClone.Core.Settings.CompanySettings? settings,
        decimal unitPrice,
        decimal quantity,
        CancellationToken cancellationToken)
    {
        if (settings?.TaxesEnabled != true)
        {
            return new TaxLineCalculation(null, 0, 0, unitPrice);
        }

        var taxCodeId = requestedTaxCodeId == Guid.Empty ? null : requestedTaxCodeId;
        taxCodeId ??= settings.DefaultSalesTaxCodeId;
        if (taxCodeId is null)
        {
            return new TaxLineCalculation(null, 0, 0, unitPrice);
        }

        var taxCode = await _taxCodes.GetByIdAsync(taxCodeId.Value, cancellationToken)
            ?? throw new InvalidOperationException("Tax code does not exist.");
        if (!taxCode.IsActive || !taxCode.CanApplyTo(TaxTransactionType.Sales))
        {
            throw new InvalidOperationException("Tax code is not active or cannot be applied to sales.");
        }

        var rate = taxCode.RatePercent;
        var taxableAmount = unitPrice * quantity;
        var netUnitPrice = unitPrice;
        if (settings.PricesIncludeTax && rate > 0)
        {
            var netLine = taxableAmount / (1 + rate / 100);
            netUnitPrice = quantity == 0 ? unitPrice : netLine / quantity;
            taxableAmount = netLine;
        }

        var taxAmount = Math.Round(taxableAmount * (rate / 100), 2, MidpointRounding.AwayFromZero);
        return new TaxLineCalculation(taxCode.Id, rate, taxAmount, netUnitPrice);
    }

    private sealed record TaxLineCalculation(Guid? TaxCodeId, decimal RatePercent, decimal TaxAmount, decimal NetUnitPrice);
}
