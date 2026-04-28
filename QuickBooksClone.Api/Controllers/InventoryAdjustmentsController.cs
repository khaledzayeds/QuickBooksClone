using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Contracts.InventoryAdjustments;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.InventoryAdjustments;
using QuickBooksClone.Core.Items;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/inventory-adjustments")]
[RequirePermission("Inventory.Adjust.Manage")]
public sealed class InventoryAdjustmentsController : ControllerBase
{
    private readonly IInventoryAdjustmentRepository _adjustments;
    private readonly IInventoryAdjustmentPostingService _postingService;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly IDocumentNumberService _documentNumbers;

    public InventoryAdjustmentsController(IInventoryAdjustmentRepository adjustments, IInventoryAdjustmentPostingService postingService, IItemRepository items, IAccountRepository accounts, IDocumentNumberService documentNumbers)
    {
        _adjustments = adjustments;
        _postingService = postingService;
        _items = items;
        _accounts = accounts;
        _documentNumbers = documentNumbers;
    }

    [HttpGet]
    [ProducesResponseType(typeof(InventoryAdjustmentListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<InventoryAdjustmentListResponse>> Search([FromQuery] string? search, [FromQuery] Guid? itemId, [FromQuery] bool includeVoid = false, [FromQuery] int page = 1, [FromQuery] int pageSize = 25, CancellationToken cancellationToken = default)
    {
        var result = await _adjustments.SearchAsync(new InventoryAdjustmentSearch(search, itemId, includeVoid, page, pageSize), cancellationToken);
        var items = new List<InventoryAdjustmentDto>();
        foreach (var adjustment in result.Items)
        {
            items.Add(await ToDtoAsync(adjustment, cancellationToken));
        }

        return Ok(new InventoryAdjustmentListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(InventoryAdjustmentDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InventoryAdjustmentDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var adjustment = await _adjustments.GetByIdAsync(id, cancellationToken);
        return adjustment is null ? NotFound() : Ok(await ToDtoAsync(adjustment, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(InventoryAdjustmentDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<InventoryAdjustmentDto>> Create(CreateInventoryAdjustmentRequest request, CancellationToken cancellationToken = default)
    {
        if (request.QuantityChange == 0) return BadRequest("Quantity change cannot be zero.");
        var item = await _items.GetByIdAsync(request.ItemId, cancellationToken);
        if (item is null) return BadRequest("Item does not exist.");
        if (item.ItemType != ItemType.Inventory) return BadRequest("Only inventory items can be adjusted.");
        if (item.InventoryAssetAccountId is null) return BadRequest("Inventory item requires an inventory asset account before adjustment.");
        if (request.QuantityChange < 0 && Math.Abs(request.QuantityChange) > item.QuantityOnHand)
        {
            return BadRequest($"Cannot decrease '{item.Name}' below zero. On hand: {item.QuantityOnHand:N2}, decrease: {Math.Abs(request.QuantityChange):N2}.");
        }

        var adjustmentAccount = await _accounts.GetByIdAsync(request.AdjustmentAccountId, cancellationToken);
        if (adjustmentAccount is null) return BadRequest("Adjustment account does not exist.");
        if (!IsAllowedAdjustmentAccount(adjustmentAccount.AccountType))
        {
            return BadRequest("Adjustment account must be an expense, cost of goods sold, other expense, income, or other income account.");
        }

        var unitCost = request.UnitCost is > 0 ? request.UnitCost.Value : item.PurchasePrice;
        if (unitCost <= 0) return BadRequest("Unit cost is required when the item purchase price is zero.");

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.InventoryAdjustment, cancellationToken);
        var adjustment = new InventoryAdjustment(request.ItemId, request.AdjustmentAccountId, request.AdjustmentDate, request.QuantityChange, unitCost, request.Reason ?? "Inventory adjustment", allocation.DocumentNo);
        adjustment.SetSyncIdentity(allocation.DeviceId, allocation.DocumentNo);
        await _adjustments.AddAsync(adjustment, cancellationToken);
        var postingResult = await _postingService.PostAsync(adjustment.Id, cancellationToken);
        if (!postingResult.Succeeded) return BadRequest(postingResult.ErrorMessage);

        var savedAdjustment = await _adjustments.GetByIdAsync(adjustment.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = adjustment.Id }, await ToDtoAsync(savedAdjustment!, cancellationToken));
    }

    private static bool IsAllowedAdjustmentAccount(AccountType accountType)
    {
        return accountType is AccountType.Expense
            or AccountType.CostOfGoodsSold
            or AccountType.OtherExpense
            or AccountType.Income
            or AccountType.OtherIncome;
    }

    private async Task<InventoryAdjustmentDto> ToDtoAsync(InventoryAdjustment adjustment, CancellationToken cancellationToken)
    {
        var item = await _items.GetByIdAsync(adjustment.ItemId, cancellationToken);
        var account = await _accounts.GetByIdAsync(adjustment.AdjustmentAccountId, cancellationToken);
        return new InventoryAdjustmentDto(adjustment.Id, adjustment.AdjustmentNumber, adjustment.ItemId, item?.Name, adjustment.AdjustmentAccountId, account?.Name, adjustment.AdjustmentDate, adjustment.QuantityChange, adjustment.UnitCost, adjustment.TotalCost, adjustment.Reason, adjustment.Status, adjustment.PostedTransactionId, adjustment.PostedAt);
    }
}
