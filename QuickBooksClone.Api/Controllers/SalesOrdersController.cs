using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Contracts.SalesOrders;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.SalesOrders;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Core.Taxes;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/sales-orders")]
[RequirePermission("Sales.Order.Manage")]
public sealed class SalesOrdersController : ControllerBase
{
    private readonly ISalesOrderRepository _orders;
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly IDocumentNumberService _documentNumbers;
    private readonly ICompanySettingsRepository _companySettings;
    private readonly ITaxCodeRepository _taxCodes;

    public SalesOrdersController(
        ISalesOrderRepository orders,
        ICustomerRepository customers,
        IItemRepository items,
        IDocumentNumberService documentNumbers,
        ICompanySettingsRepository companySettings,
        ITaxCodeRepository taxCodes)
    {
        _orders = orders;
        _customers = customers;
        _items = items;
        _documentNumbers = documentNumbers;
        _companySettings = companySettings;
        _taxCodes = taxCodes;
    }

    [HttpGet]
    [ProducesResponseType(typeof(SalesOrderListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<SalesOrderListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] Guid? customerId,
        [FromQuery] bool includeClosed = false,
        [FromQuery] bool includeCancelled = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _orders.SearchAsync(new SalesOrderSearch(search, customerId, includeClosed, includeCancelled, page, pageSize), cancellationToken);
        var items = new List<SalesOrderDto>();
        foreach (var order in result.Items)
        {
            items.Add(await ToDtoAsync(order, cancellationToken));
        }

        return Ok(new SalesOrderListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(SalesOrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SalesOrderDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var order = await _orders.GetByIdAsync(id, cancellationToken);
        return order is null ? NotFound() : Ok(await ToDtoAsync(order, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(SalesOrderDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<SalesOrderDto>> Create(CreateSalesOrderRequest request, CancellationToken cancellationToken = default)
    {
        var saveMode = request.SaveMode == 0 ? SalesOrderSaveMode.SaveAsOpen : request.SaveMode;
        if (!Enum.IsDefined(saveMode))
        {
            return BadRequest("Invalid sales order save mode.");
        }

        var customer = await _customers.GetByIdAsync(request.CustomerId, cancellationToken);
        if (customer is null)
        {
            return BadRequest("Customer does not exist.");
        }

        if (!customer.IsActive)
        {
            return BadRequest("Cannot create a sales order for an inactive customer.");
        }

        if (request.Lines.Count == 0)
        {
            return BadRequest("Sales order must have at least one line.");
        }

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.SalesOrder, cancellationToken);
        var taxSettings = await _companySettings.GetAsync(cancellationToken);
        var order = new SalesOrder(request.CustomerId, request.OrderDate, request.ExpectedDate, allocation.DocumentNo);
        order.SetSyncIdentity(allocation.DeviceId, allocation.DocumentNo);

        foreach (var line in request.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return BadRequest($"Item does not exist: {line.ItemId}");
            }

            if (!item.IsActive)
            {
                return BadRequest($"Cannot use inactive item on a sales order: {item.Name}");
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

            order.AddLine(new SalesOrderLine(item.Id, description, line.Quantity, tax.NetUnitPrice, taxCodeId: tax.TaxCodeId, taxRatePercent: tax.RatePercent, taxAmount: tax.TaxAmount));
        }

        await _orders.AddAsync(order, cancellationToken);

        if (saveMode == SalesOrderSaveMode.SaveAsOpen)
        {
            await _orders.MarkOpenAsync(order.Id, cancellationToken);
        }

        var saved = await _orders.GetByIdAsync(order.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = order.Id }, await ToDtoAsync(saved!, cancellationToken));
    }

    [HttpPost("{id:guid}/open")]
    public async Task<ActionResult<SalesOrderDto>> Open(Guid id, CancellationToken cancellationToken = default)
    {
        var order = await _orders.GetByIdAsync(id, cancellationToken);
        if (order is null)
        {
            return NotFound();
        }

        try
        {
            await _orders.MarkOpenAsync(id, cancellationToken);
            var updated = await _orders.GetByIdAsync(id, cancellationToken);
            return Ok(await ToDtoAsync(updated!, cancellationToken));
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPost("{id:guid}/close")]
    public async Task<ActionResult<SalesOrderDto>> Close(Guid id, CancellationToken cancellationToken = default)
    {
        var order = await _orders.GetByIdAsync(id, cancellationToken);
        if (order is null)
        {
            return NotFound();
        }

        try
        {
            await _orders.CloseAsync(id, cancellationToken);
            var updated = await _orders.GetByIdAsync(id, cancellationToken);
            return Ok(await ToDtoAsync(updated!, cancellationToken));
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpPatch("{id:guid}/cancel")]
    public async Task<ActionResult<SalesOrderDto>> Cancel(Guid id, CancellationToken cancellationToken = default)
    {
        var order = await _orders.GetByIdAsync(id, cancellationToken);
        if (order is null)
        {
            return NotFound();
        }

        try
        {
            await _orders.CancelAsync(id, cancellationToken);
            var updated = await _orders.GetByIdAsync(id, cancellationToken);
            return Ok(await ToDtoAsync(updated!, cancellationToken));
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    private async Task<SalesOrderDto> ToDtoAsync(SalesOrder order, CancellationToken cancellationToken)
    {
        var customer = await _customers.GetByIdAsync(order.CustomerId, cancellationToken);
        return new SalesOrderDto(
            order.Id,
            order.OrderNumber,
            order.CustomerId,
            customer?.DisplayName,
            order.EstimateId,
            order.OrderDate,
            order.ExpectedDate,
            order.Status,
            order.Subtotal,
            order.TaxAmount,
            order.TotalAmount,
            order.OpenedAt,
            order.ClosedAt,
            order.CancelledAt,
            order.Lines.Select(line => new SalesOrderLineDto(
                line.Id,
                line.ItemId,
                line.EstimateLineId,
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
