using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.PurchaseOrders;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.PurchaseOrders;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Core.Taxes;
using QuickBooksClone.Core.Vendors;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/purchase-orders")]
[RequirePermission("Purchases.Order.Manage")]
public sealed class PurchaseOrderDraftUpdatesController : ControllerBase
{
    private readonly IPurchaseOrderRepository _orders;
    private readonly IVendorRepository _vendors;
    private readonly IItemRepository _items;
    private readonly ICompanySettingsRepository _companySettings;
    private readonly ITaxCodeRepository _taxCodes;
    private readonly QuickBooksCloneDbContext _dbContext;

    public PurchaseOrderDraftUpdatesController(
        IPurchaseOrderRepository orders,
        IVendorRepository vendors,
        IItemRepository items,
        ICompanySettingsRepository companySettings,
        ITaxCodeRepository taxCodes,
        QuickBooksCloneDbContext dbContext)
    {
        _orders = orders;
        _vendors = vendors;
        _items = items;
        _companySettings = companySettings;
        _taxCodes = taxCodes;
        _dbContext = dbContext;
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(PurchaseOrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PurchaseOrderDto>> UpdateDraft(Guid id, UpdatePurchaseOrderRequest request, CancellationToken cancellationToken = default)
    {
        var order = await _orders.GetByIdAsync(id, cancellationToken);
        if (order is null)
        {
            return NotFound();
        }

        if (order.Status != PurchaseOrderStatus.Draft)
        {
            return BadRequest("Only draft purchase orders can be edited.");
        }

        var vendor = await _vendors.GetByIdAsync(request.VendorId, cancellationToken);
        if (vendor is null)
        {
            return BadRequest("Vendor does not exist.");
        }

        if (!vendor.IsActive)
        {
            return BadRequest("Cannot use an inactive vendor.");
        }

        if (request.ExpectedDate < request.OrderDate)
        {
            return BadRequest("Expected date cannot be before purchase order date.");
        }

        if (request.Lines.Count == 0)
        {
            return BadRequest("Purchase order must have at least one line.");
        }

        var taxSettings = await _companySettings.GetAsync(cancellationToken);
        var lines = new List<PurchaseOrderLine>();
        foreach (var line in request.Lines)
        {
            var build = await BuildLineAsync(line, taxSettings, cancellationToken);
            if (build.Error is not null)
            {
                return BadRequest(build.Error);
            }

            lines.Add(build.Line!);
        }

        try
        {
            order.UpdateDraftHeader(request.VendorId, request.OrderDate, request.ExpectedDate);
            order.ReplaceDraftLines(lines);
            await _dbContext.SaveChangesAsync(cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }

        var updated = await _orders.GetByIdAsync(id, cancellationToken);
        return Ok(await ToDtoAsync(updated!, cancellationToken));
    }

    private async Task<(PurchaseOrderLine? Line, string? Error)> BuildLineAsync(CreatePurchaseOrderLineRequest line, CompanySettings? settings, CancellationToken cancellationToken)
    {
        if (line.ItemId == Guid.Empty)
        {
            return (null, "Line item is required.");
        }

        if (line.Quantity <= 0)
        {
            return (null, "Line quantity must be greater than zero.");
        }

        if (line.UnitCost < 0)
        {
            return (null, "Line unit cost cannot be negative.");
        }

        var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
        if (item is null)
        {
            return (null, $"Item does not exist: {line.ItemId}");
        }

        if (!item.IsActive)
        {
            return (null, $"Cannot use inactive item on a purchase order: {item.Name}");
        }

        var unitCost = line.UnitCost > 0 ? line.UnitCost : item.PurchasePrice;
        if (unitCost <= 0)
        {
            return (null, $"Unit cost is required for '{item.Name}' because the item purchase price is zero.");
        }

        var description = string.IsNullOrWhiteSpace(line.Description) ? item.Name : line.Description.Trim();
        try
        {
            var tax = await ResolvePurchaseTaxAsync(line.TaxCodeId, settings, unitCost, line.Quantity, cancellationToken);
            return (new PurchaseOrderLine(item.Id, description, line.Quantity, tax.NetUnitCost, tax.TaxCodeId, tax.RatePercent, tax.TaxAmount), null);
        }
        catch (InvalidOperationException exception)
        {
            return (null, exception.Message);
        }
    }

    private async Task<TaxLineCalculation> ResolvePurchaseTaxAsync(Guid? requestedTaxCodeId, CompanySettings? settings, decimal unitCost, decimal quantity, CancellationToken cancellationToken)
    {
        if (settings?.TaxesEnabled != true)
        {
            return new TaxLineCalculation(null, 0, 0, unitCost);
        }

        var taxCodeId = requestedTaxCodeId == Guid.Empty ? null : requestedTaxCodeId;
        taxCodeId ??= settings.DefaultPurchaseTaxCodeId;
        if (taxCodeId is null)
        {
            return new TaxLineCalculation(null, 0, 0, unitCost);
        }

        var taxCode = await _taxCodes.GetByIdAsync(taxCodeId.Value, cancellationToken)
            ?? throw new InvalidOperationException("Tax code does not exist.");
        if (!taxCode.IsActive || !taxCode.CanApplyTo(TaxTransactionType.Purchase))
        {
            throw new InvalidOperationException("Tax code is not active or cannot be applied to purchases.");
        }

        var rate = taxCode.RatePercent;
        var taxableAmount = unitCost * quantity;
        var netUnitCost = unitCost;
        if (settings.PricesIncludeTax && rate > 0)
        {
            var netLine = taxableAmount / (1 + rate / 100);
            netUnitCost = quantity == 0 ? unitCost : netLine / quantity;
            taxableAmount = netLine;
        }

        var taxAmount = Math.Round(taxableAmount * (rate / 100), 2, MidpointRounding.AwayFromZero);
        return new TaxLineCalculation(taxCode.Id, rate, taxAmount, netUnitCost);
    }

    private async Task<PurchaseOrderDto> ToDtoAsync(PurchaseOrder order, CancellationToken cancellationToken)
    {
        var vendor = await _vendors.GetByIdAsync(order.VendorId, cancellationToken);
        return new PurchaseOrderDto(
            order.Id,
            order.OrderNumber,
            order.VendorId,
            vendor?.DisplayName,
            order.OrderDate,
            order.ExpectedDate,
            order.Status,
            order.Subtotal,
            order.TaxAmount,
            order.TotalAmount,
            order.OpenedAt,
            order.ClosedAt,
            order.CancelledAt,
            order.Lines.Select(line => new PurchaseOrderLineDto(
                line.Id,
                line.ItemId,
                line.Description,
                line.Quantity,
                line.UnitCost,
                line.TaxCodeId,
                line.TaxRatePercent,
                line.TaxAmount,
                line.LineTotal)).ToList());
    }

    private sealed record TaxLineCalculation(Guid? TaxCodeId, decimal RatePercent, decimal TaxAmount, decimal NetUnitCost);
}
