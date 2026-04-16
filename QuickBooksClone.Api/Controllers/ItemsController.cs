using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Items;
using QuickBooksClone.Core.Items;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/items")]
public sealed class ItemsController : ControllerBase
{
    private readonly IItemRepository _items;

    public ItemsController(IItemRepository items)
    {
        _items = items;
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
    public async Task<ActionResult<ItemDto>> Create(CreateItemRequest request, CancellationToken cancellationToken = default)
    {
        var item = new Item(
            request.Name,
            request.ItemType,
            request.Sku,
            request.Barcode,
            request.SalesPrice,
            request.PurchasePrice,
            request.QuantityOnHand,
            request.Unit ?? "pcs");

        await _items.AddAsync(item, cancellationToken);

        return CreatedAtAction(nameof(Get), new { id = item.Id }, ToDto(item));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ItemDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ItemDto>> Update(Guid id, UpdateItemRequest request, CancellationToken cancellationToken = default)
    {
        var item = await _items.UpdateAsync(
            id,
            request.Name,
            request.ItemType,
            request.Sku,
            request.Barcode,
            request.SalesPrice,
            request.PurchasePrice,
            request.Unit ?? "pcs",
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
            item.IsActive);
    }
}
