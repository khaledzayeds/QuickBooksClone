using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Items;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.OpeningBalances;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/items")]
public sealed class ItemsController : ControllerBase
{
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly IOpeningBalancePostingService _openingBalances;

    public ItemsController(IItemRepository items, IAccountRepository accounts, IOpeningBalancePostingService openingBalances)
    {
        _items = items;
        _accounts = accounts;
        _openingBalances = openingBalances;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ItemListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<ItemListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] bool includeInactive = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _items.SearchAsync(new ItemSearch(search, includeInactive, page, pageSize), cancellationToken);

        return Ok(new ItemListResponse(
            result.Items.Select(ToDto).ToList(),
            result.TotalCount,
            result.Page,
            result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ItemDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ItemDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var item = await _items.GetByIdAsync(id, cancellationToken);
        return item is null ? NotFound() : Ok(ToDto(item));
    }

    [HttpPost]
    [ProducesResponseType(typeof(ItemDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ItemDto>> Create(CreateItemRequest request, CancellationToken cancellationToken = default)
    {
        var duplicateValidation = await ValidateUniqueItemAsync(request.Name, request.Sku, request.Barcode, null, cancellationToken);
        if (duplicateValidation is not null)
        {
            return Conflict(duplicateValidation);
        }

        var accountValidation = await ValidateAccountLinksAsync(
            request.IncomeAccountId,
            request.InventoryAssetAccountId,
            request.CogsAccountId,
            request.ExpenseAccountId,
            cancellationToken);

        if (accountValidation is not null)
        {
            return BadRequest(accountValidation);
        }

        var openingBalanceValidation = ValidateInventoryOpeningBalance(request);
        if (openingBalanceValidation is not null)
        {
            return BadRequest(openingBalanceValidation);
        }

        var item = new Item(
            request.Name,
            request.ItemType,
            request.Sku,
            request.Barcode,
            request.SalesPrice,
            request.PurchasePrice,
            request.QuantityOnHand,
            request.Unit ?? "pcs",
            request.IncomeAccountId,
            request.InventoryAssetAccountId,
            request.CogsAccountId,
            request.ExpenseAccountId);

        await _items.AddAsync(item, cancellationToken);
        var openingBalanceResult = await _openingBalances.PostItemOpeningBalanceAsync(item, cancellationToken);
        if (!openingBalanceResult.Succeeded)
        {
            return BadRequest(openingBalanceResult.ErrorMessage);
        }

        return CreatedAtAction(nameof(Get), new { id = item.Id }, ToDto(item));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ItemDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ItemDto>> Update(Guid id, UpdateItemRequest request, CancellationToken cancellationToken = default)
    {
        var duplicateValidation = await ValidateUniqueItemAsync(request.Name, request.Sku, request.Barcode, id, cancellationToken);
        if (duplicateValidation is not null)
        {
            return Conflict(duplicateValidation);
        }

        var accountValidation = await ValidateAccountLinksAsync(
            request.IncomeAccountId,
            request.InventoryAssetAccountId,
            request.CogsAccountId,
            request.ExpenseAccountId,
            cancellationToken);

        if (accountValidation is not null)
        {
            return BadRequest(accountValidation);
        }

        var item = await _items.UpdateAsync(
            id,
            request.Name,
            request.ItemType,
            request.Sku,
            request.Barcode,
            request.SalesPrice,
            request.PurchasePrice,
            request.Unit ?? "pcs",
            request.IncomeAccountId,
            request.InventoryAssetAccountId,
            request.CogsAccountId,
            request.ExpenseAccountId,
            cancellationToken);

        return item is null ? NotFound() : Ok(ToDto(item));
    }

    [HttpPatch("{id:guid}/active")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetActive(Guid id, SetItemActiveRequest request, CancellationToken cancellationToken = default)
    {
        var updated = await _items.SetActiveAsync(id, request.IsActive, cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    [HttpPatch("{id:guid}/quantity")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> AdjustQuantity(Guid id, AdjustItemQuantityRequest request, CancellationToken cancellationToken = default)
    {
        var updated = await _items.AdjustQuantityAsync(id, request.QuantityOnHand, cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    private async Task<string?> ValidateUniqueItemAsync(
        string name,
        string? sku,
        string? barcode,
        Guid? excludingId,
        CancellationToken cancellationToken)
    {
        if (await _items.NameExistsAsync(name, excludingId, cancellationToken))
        {
            return "Item name already exists.";
        }

        if (!string.IsNullOrWhiteSpace(sku) && await _items.SkuExistsAsync(sku, excludingId, cancellationToken))
        {
            return "Item SKU already exists.";
        }

        if (!string.IsNullOrWhiteSpace(barcode) && await _items.BarcodeExistsAsync(barcode, excludingId, cancellationToken))
        {
            return "Item barcode already exists.";
        }

        return null;
    }

    private static ItemDto ToDto(Item item)
    {
        return new ItemDto(
            item.Id,
            item.Name,
            item.ItemType,
            item.Sku,
            item.Barcode,
            item.SalesPrice,
            item.PurchasePrice,
            item.QuantityOnHand,
            item.Unit,
            item.IncomeAccountId,
            item.InventoryAssetAccountId,
            item.CogsAccountId,
            item.ExpenseAccountId,
            item.IsActive);
    }

    private async Task<string?> ValidateAccountLinksAsync(
        Guid? incomeAccountId,
        Guid? inventoryAssetAccountId,
        Guid? cogsAccountId,
        Guid? expenseAccountId,
        CancellationToken cancellationToken)
    {
        foreach (var accountId in new[] { incomeAccountId, inventoryAssetAccountId, cogsAccountId, expenseAccountId }.Where(id => id is not null))
        {
            if (await _accounts.GetByIdAsync(accountId!.Value, cancellationToken) is null)
            {
                return $"Account does not exist: {accountId}";
            }
        }

        return null;
    }

    private static string? ValidateInventoryOpeningBalance(CreateItemRequest request)
    {
        if (request.ItemType != ItemType.Inventory || request.QuantityOnHand <= 0)
        {
            return null;
        }

        if (request.PurchasePrice <= 0)
        {
            return "Inventory opening quantity requires a purchase price to create an opening inventory value.";
        }

        if (request.InventoryAssetAccountId is null)
        {
            return "Inventory opening quantity requires an inventory asset account.";
        }

        return null;
    }
}
