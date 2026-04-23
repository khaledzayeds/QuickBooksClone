using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.PurchaseOrders;
using QuickBooksClone.Api.Contracts.PurchaseWorkflow;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.PurchaseOrders;
using QuickBooksClone.Core.PurchaseWorkflow;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/purchase-orders")]
public sealed class PurchaseOrdersController : ControllerBase
{
    private readonly IPurchaseOrderRepository _orders;
    private readonly IVendorRepository _vendors;
    private readonly IItemRepository _items;
    private readonly IDocumentNumberService _documentNumbers;
    private readonly IPurchaseWorkflowService _workflow;

    public PurchaseOrdersController(IPurchaseOrderRepository orders, IVendorRepository vendors, IItemRepository items, IDocumentNumberService documentNumbers, IPurchaseWorkflowService workflow)
    {
        _orders = orders;
        _vendors = vendors;
        _items = items;
        _documentNumbers = documentNumbers;
        _workflow = workflow;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PurchaseOrderListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<PurchaseOrderListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] Guid? vendorId,
        [FromQuery] bool includeClosed = false,
        [FromQuery] bool includeCancelled = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _orders.SearchAsync(new PurchaseOrderSearch(search, vendorId, includeClosed, includeCancelled, page, pageSize), cancellationToken);
        var items = new List<PurchaseOrderDto>();
        foreach (var order in result.Items)
        {
            items.Add(await ToDtoAsync(order, cancellationToken));
        }

        return Ok(new PurchaseOrderListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(PurchaseOrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PurchaseOrderDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var order = await _orders.GetByIdAsync(id, cancellationToken);
        return order is null ? NotFound() : Ok(await ToDtoAsync(order, cancellationToken));
    }

    [HttpGet("{id:guid}/receiving-plan")]
    [ProducesResponseType(typeof(PurchaseOrderReceivingPlanDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PurchaseOrderReceivingPlanDto>> GetReceivingPlan(Guid id, CancellationToken cancellationToken = default)
    {
        var plan = await _workflow.GetReceivingPlanAsync(id, cancellationToken);
        if (plan is null)
        {
            return NotFound();
        }

        var vendor = await _vendors.GetByIdAsync(plan.VendorId, cancellationToken);
        return Ok(new PurchaseOrderReceivingPlanDto(
            plan.PurchaseOrderId,
            plan.OrderNumber,
            plan.VendorId,
            vendor?.DisplayName,
            plan.Status,
            plan.CanReceive,
            plan.IsFullyReceived,
            plan.TotalOrderedQuantity,
            plan.TotalReceivedQuantity,
            plan.TotalRemainingQuantity,
            plan.Lines.Select(line => new PurchaseOrderReceivingPlanLineDto(
                line.PurchaseOrderLineId,
                line.ItemId,
                line.Description,
                line.OrderedQuantity,
                line.ReceivedQuantity,
                line.RemainingQuantity,
                line.SuggestedReceiveQuantity,
                line.UnitCost)).ToList(),
            plan.LinkedReceipts.Select(receipt => new LinkedInventoryReceiptReferenceDto(
                receipt.Id,
                receipt.ReceiptNumber,
                receipt.ReceiptDate,
                receipt.Status)).ToList()));
    }

    [HttpPost]
    [ProducesResponseType(typeof(PurchaseOrderDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PurchaseOrderDto>> Create(CreatePurchaseOrderRequest request, CancellationToken cancellationToken = default)
    {
        var saveMode = request.SaveMode == 0 ? PurchaseOrderSaveMode.SaveAsOpen : request.SaveMode;
        if (!Enum.IsDefined(saveMode))
        {
            return BadRequest("Invalid purchase order save mode.");
        }

        var vendor = await _vendors.GetByIdAsync(request.VendorId, cancellationToken);
        if (vendor is null)
        {
            return BadRequest("Vendor does not exist.");
        }

        if (!vendor.IsActive)
        {
            return BadRequest("Cannot create a purchase order for an inactive vendor.");
        }

        if (request.Lines.Count == 0)
        {
            return BadRequest("Purchase order must have at least one line.");
        }

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.PurchaseOrder, cancellationToken);
        var order = new PurchaseOrder(request.VendorId, request.OrderDate, request.ExpectedDate, allocation.DocumentNo);
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
                return BadRequest($"Cannot use inactive item on a purchase order: {item.Name}");
            }

            var unitCost = line.UnitCost > 0 ? line.UnitCost : item.PurchasePrice;
            var description = string.IsNullOrWhiteSpace(line.Description) ? item.Name : line.Description;
            order.AddLine(new PurchaseOrderLine(item.Id, description, line.Quantity, unitCost));
        }

        await _orders.AddAsync(order, cancellationToken);

        if (saveMode == PurchaseOrderSaveMode.SaveAsOpen)
        {
            await _orders.MarkOpenAsync(order.Id, cancellationToken);
        }

        var saved = await _orders.GetByIdAsync(order.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = order.Id }, await ToDtoAsync(saved!, cancellationToken));
    }

    [HttpPost("{id:guid}/open")]
    [ProducesResponseType(typeof(PurchaseOrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PurchaseOrderDto>> Open(Guid id, CancellationToken cancellationToken = default)
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
    [ProducesResponseType(typeof(PurchaseOrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PurchaseOrderDto>> Close(Guid id, CancellationToken cancellationToken = default)
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
    [ProducesResponseType(typeof(PurchaseOrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PurchaseOrderDto>> Cancel(Guid id, CancellationToken cancellationToken = default)
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
                line.LineTotal)).ToList());
    }
}
