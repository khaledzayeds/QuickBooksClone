using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Contracts.PurchaseWorkflow;
using QuickBooksClone.Api.Contracts.ReceiveInventory;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.PurchaseOrders;
using QuickBooksClone.Core.PurchaseWorkflow;
using QuickBooksClone.Core.ReceiveInventory;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/receive-inventory")]
[RequirePermission("Purchases.Receive.Manage")]
public sealed class ReceiveInventoryController : ControllerBase
{
    private readonly IInventoryReceiptRepository _receipts;
    private readonly IInventoryReceiptPostingService _postingService;
    private readonly IVendorRepository _vendors;
    private readonly IPurchaseOrderRepository _orders;
    private readonly IItemRepository _items;
    private readonly IDocumentNumberService _documentNumbers;
    private readonly IPurchaseWorkflowService _workflow;

    public ReceiveInventoryController(
        IInventoryReceiptRepository receipts,
        IInventoryReceiptPostingService postingService,
        IVendorRepository vendors,
        IPurchaseOrderRepository orders,
        IItemRepository items,
        IDocumentNumberService documentNumbers,
        IPurchaseWorkflowService workflow)
    {
        _receipts = receipts;
        _postingService = postingService;
        _vendors = vendors;
        _orders = orders;
        _items = items;
        _documentNumbers = documentNumbers;
        _workflow = workflow;
    }

    [HttpGet]
    [ProducesResponseType(typeof(InventoryReceiptListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<InventoryReceiptListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] Guid? vendorId,
        [FromQuery] Guid? purchaseOrderId,
        [FromQuery] bool includeVoid = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _receipts.SearchAsync(new InventoryReceiptSearch(search, vendorId, purchaseOrderId, includeVoid, page, pageSize), cancellationToken);
        var items = new List<InventoryReceiptDto>();
        foreach (var receipt in result.Items)
        {
            items.Add(await ToDtoAsync(receipt, cancellationToken));
        }

        return Ok(new InventoryReceiptListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(InventoryReceiptDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InventoryReceiptDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var receipt = await _receipts.GetByIdAsync(id, cancellationToken);
        return receipt is null ? NotFound() : Ok(await ToDtoAsync(receipt, cancellationToken));
    }

    [HttpGet("{id:guid}/billing-plan")]
    [ProducesResponseType(typeof(InventoryReceiptBillingPlanDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InventoryReceiptBillingPlanDto>> GetBillingPlan(Guid id, CancellationToken cancellationToken = default)
    {
        var plan = await _workflow.GetBillingPlanAsync(id, cancellationToken);
        if (plan is null)
        {
            return NotFound();
        }

        var vendor = await _vendors.GetByIdAsync(plan.VendorId, cancellationToken);
        PurchaseOrder? order = null;
        if (plan.PurchaseOrderId is not null)
        {
            order = await _orders.GetByIdAsync(plan.PurchaseOrderId.Value, cancellationToken);
        }

        return Ok(new InventoryReceiptBillingPlanDto(
            plan.InventoryReceiptId,
            plan.ReceiptNumber,
            plan.VendorId,
            vendor?.DisplayName,
            plan.PurchaseOrderId,
            order?.OrderNumber,
            plan.Status,
            plan.CanBill,
            plan.IsFullyBilled,
            plan.TotalReceivedQuantity,
            plan.TotalBilledQuantity,
            plan.TotalRemainingQuantity,
            plan.Lines.Select(line => new InventoryReceiptBillingPlanLineDto(
                line.InventoryReceiptLineId,
                line.ItemId,
                line.PurchaseOrderLineId,
                line.Description,
                line.ReceivedQuantity,
                line.BilledQuantity,
                line.RemainingQuantity,
                line.SuggestedBillQuantity,
                line.UnitCost)).ToList(),
            plan.LinkedBills.Select(bill => new LinkedPurchaseBillReferenceDto(
                bill.Id,
                bill.BillNumber,
                bill.BillDate,
                bill.Status)).ToList()));
    }

    [HttpPost]
    [ProducesResponseType(typeof(InventoryReceiptDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<InventoryReceiptDto>> Create(CreateInventoryReceiptRequest request, CancellationToken cancellationToken = default)
    {
        var saveMode = request.SaveMode == 0 ? InventoryReceiptSaveMode.SaveAndPost : request.SaveMode;
        if (!Enum.IsDefined(saveMode))
        {
            return BadRequest("Invalid receive inventory save mode.");
        }

        if (request.Lines.Count == 0)
        {
            return BadRequest("Inventory receipt must have at least one line.");
        }

        var vendor = await _vendors.GetByIdAsync(request.VendorId, cancellationToken);
        if (vendor is null)
        {
            return BadRequest("Vendor does not exist.");
        }

        if (!vendor.IsActive)
        {
            return BadRequest("Cannot receive inventory for an inactive vendor.");
        }

        PurchaseOrder? order = null;
        Dictionary<Guid, decimal> alreadyReceived = [];
        if (request.PurchaseOrderId is not null)
        {
            order = await _orders.GetByIdAsync(request.PurchaseOrderId.Value, cancellationToken);
            if (order is null)
            {
                return BadRequest("Purchase order does not exist.");
            }

            if (order.VendorId != request.VendorId)
            {
                return BadRequest("Purchase order vendor does not match the selected vendor.");
            }

            if (order.Status != PurchaseOrderStatus.Open)
            {
                return BadRequest("Inventory can only be received against an open purchase order.");
            }

            var orderLineIds = order.Lines.Select(line => line.Id);
            alreadyReceived = await _receipts.GetReceivedQuantitiesByPurchaseOrderLineIdsAsync(orderLineIds, cancellationToken);
        }

        var requestedQuantitiesByOrderLine = request.Lines
            .Where(line => line.PurchaseOrderLineId.HasValue && line.PurchaseOrderLineId != Guid.Empty)
            .GroupBy(line => line.PurchaseOrderLineId!.Value)
            .ToDictionary(group => group.Key, group => group.Sum(line => line.Quantity));

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.InventoryReceipt, cancellationToken);
        var receipt = new InventoryReceipt(
            request.VendorId,
            request.ReceiptDate,
            request.PurchaseOrderId,
            allocation.DocumentNo);
        receipt.SetSyncIdentity(allocation.DeviceId, allocation.DocumentNo);

        foreach (var line in request.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return BadRequest($"Item does not exist: {line.ItemId}");
            }

            if (!item.IsActive)
            {
                return BadRequest($"Cannot receive inactive item: {item.Name}");
            }

            if (item.ItemType != ItemType.Inventory)
            {
                return BadRequest($"Receive Inventory only supports inventory items. '{item.Name}' is {item.ItemType}.");
            }

            Guid? purchaseOrderLineId = null;
            if (line.PurchaseOrderLineId is not null && line.PurchaseOrderLineId != Guid.Empty)
            {
                if (order is null)
                {
                    return BadRequest("Cannot specify purchase order line without selecting a purchase order.");
                }

                var orderLine = order.Lines.FirstOrDefault(current => current.Id == line.PurchaseOrderLineId.Value);
                if (orderLine is null)
                {
                    return BadRequest($"Purchase order line does not exist on the selected order: {line.PurchaseOrderLineId}");
                }

                if (orderLine.ItemId != line.ItemId)
                {
                    return BadRequest("Purchase order line item does not match the received item.");
                }

                var already = alreadyReceived.GetValueOrDefault(orderLine.Id);
                var requested = requestedQuantitiesByOrderLine.GetValueOrDefault(orderLine.Id);
                if (already + requested > orderLine.Quantity)
                {
                    return BadRequest($"Received quantity exceeds purchase order quantity for '{item.Name}'. Ordered: {orderLine.Quantity:N2}, already received: {already:N2}, requested now: {requested:N2}.");
                }

                purchaseOrderLineId = orderLine.Id;
            }

            var unitCost = line.UnitCost > 0 ? line.UnitCost : item.PurchasePrice;
            if (unitCost <= 0)
            {
                return BadRequest($"Unit cost is required for '{item.Name}' because the item purchase price is zero.");
            }

            var description = string.IsNullOrWhiteSpace(line.Description) ? item.Name : line.Description.Trim();
            receipt.AddLine(new InventoryReceiptLine(item.Id, description, line.Quantity, unitCost, purchaseOrderLineId));
        }

        await _receipts.AddAsync(receipt, cancellationToken);

        if (saveMode == InventoryReceiptSaveMode.SaveAndPost)
        {
            var postingResult = await _postingService.PostAsync(receipt.Id, cancellationToken);
            if (!postingResult.Succeeded)
            {
                return BadRequest(postingResult.ErrorMessage);
            }
        }

        var savedReceipt = await _receipts.GetByIdAsync(receipt.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = receipt.Id }, await ToDtoAsync(savedReceipt!, cancellationToken));
    }

    [HttpPost("{id:guid}/post")]
    [ProducesResponseType(typeof(InventoryReceiptDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InventoryReceiptDto>> Post(Guid id, CancellationToken cancellationToken = default)
    {
        var receipt = await _receipts.GetByIdAsync(id, cancellationToken);
        if (receipt is null)
        {
            return NotFound();
        }

        var postingResult = await _postingService.PostAsync(id, cancellationToken);
        if (!postingResult.Succeeded)
        {
            return BadRequest(postingResult.ErrorMessage);
        }

        var updated = await _receipts.GetByIdAsync(id, cancellationToken);
        return Ok(await ToDtoAsync(updated!, cancellationToken));
    }

    [HttpPatch("{id:guid}/void")]
    [ProducesResponseType(typeof(InventoryReceiptDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InventoryReceiptDto>> Void(Guid id, CancellationToken cancellationToken = default)
    {
        var receipt = await _receipts.GetByIdAsync(id, cancellationToken);
        if (receipt is null)
        {
            return NotFound();
        }

        var result = await _postingService.VoidAsync(id, cancellationToken);
        if (!result.Succeeded)
        {
            return BadRequest(result.ErrorMessage);
        }

        var updated = await _receipts.GetByIdAsync(id, cancellationToken);
        return Ok(await ToDtoAsync(updated!, cancellationToken));
    }

    private async Task<InventoryReceiptDto> ToDtoAsync(InventoryReceipt receipt, CancellationToken cancellationToken)
    {
        var vendor = await _vendors.GetByIdAsync(receipt.VendorId, cancellationToken);
        var order = receipt.PurchaseOrderId is null ? null : await _orders.GetByIdAsync(receipt.PurchaseOrderId.Value, cancellationToken);

        return new InventoryReceiptDto(
            receipt.Id,
            receipt.ReceiptNumber,
            receipt.VendorId,
            vendor?.DisplayName,
            receipt.PurchaseOrderId,
            order?.OrderNumber,
            receipt.ReceiptDate,
            receipt.Status,
            receipt.TotalAmount,
            receipt.PostedTransactionId,
            receipt.PostedAt,
            receipt.ReversalTransactionId,
            receipt.VoidedAt,
            receipt.Lines.Select(line => new InventoryReceiptLineDto(
                line.Id,
                line.ItemId,
                line.PurchaseOrderLineId,
                line.Description,
                line.Quantity,
                line.UnitCost,
                line.LineTotal)).ToList());
    }
}
