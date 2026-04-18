using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.PurchaseBills;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/purchase-bills")]
public sealed class PurchaseBillsController : ControllerBase
{
    private readonly IPurchaseBillRepository _bills;
    private readonly IVendorRepository _vendors;
    private readonly IItemRepository _items;
    private readonly IPurchaseBillPostingService _postingService;

    public PurchaseBillsController(
        IPurchaseBillRepository bills,
        IVendorRepository vendors,
        IItemRepository items,
        IPurchaseBillPostingService postingService)
    {
        _bills = bills;
        _vendors = vendors;
        _items = items;
        _postingService = postingService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PurchaseBillListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<PurchaseBillListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] Guid? vendorId,
        [FromQuery] bool includeVoid = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _bills.SearchAsync(new PurchaseBillSearch(search, vendorId, includeVoid, page, pageSize), cancellationToken);
        var items = new List<PurchaseBillDto>();

        foreach (var bill in result.Items)
        {
            items.Add(await ToDtoAsync(bill, cancellationToken));
        }

        return Ok(new PurchaseBillListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(PurchaseBillDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PurchaseBillDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var bill = await _bills.GetByIdAsync(id, cancellationToken);
        return bill is null ? NotFound() : Ok(await ToDtoAsync(bill, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(PurchaseBillDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PurchaseBillDto>> Create(CreatePurchaseBillRequest request, CancellationToken cancellationToken = default)
    {
        var saveMode = request.SaveMode == 0 ? PurchaseBillSaveMode.SaveAndPost : request.SaveMode;
        if (!Enum.IsDefined(saveMode))
        {
            return BadRequest("Invalid purchase bill save mode.");
        }

        var vendor = await _vendors.GetByIdAsync(request.VendorId, cancellationToken);
        if (vendor is null)
        {
            return BadRequest("Vendor does not exist.");
        }

        if (!vendor.IsActive)
        {
            return BadRequest("Cannot create a purchase bill for an inactive vendor.");
        }

        if (request.Lines.Count == 0)
        {
            return BadRequest("Purchase bill must have at least one line.");
        }

        var bill = new PurchaseBill(request.VendorId, request.BillDate, request.DueDate);

        foreach (var line in request.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return BadRequest($"Item does not exist: {line.ItemId}");
            }

            var unitCost = line.UnitCost > 0 ? line.UnitCost : item.PurchasePrice;
            var description = string.IsNullOrWhiteSpace(line.Description) ? item.Name : line.Description;
            bill.AddLine(new PurchaseBillLine(item.Id, description, line.Quantity, unitCost));
        }

        await _bills.AddAsync(bill, cancellationToken);

        if (saveMode == PurchaseBillSaveMode.SaveAndPost)
        {
            var postingResult = await _postingService.PostAsync(bill.Id, cancellationToken);
            if (!postingResult.Succeeded)
            {
                return BadRequest(postingResult.ErrorMessage);
            }
        }

        var savedBill = await _bills.GetByIdAsync(bill.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = bill.Id }, await ToDtoAsync(savedBill!, cancellationToken));
    }

    [HttpPost("{id:guid}/post")]
    [ProducesResponseType(typeof(PurchaseBillDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PurchaseBillDto>> Post(Guid id, CancellationToken cancellationToken = default)
    {
        var bill = await _bills.GetByIdAsync(id, cancellationToken);
        if (bill is null)
        {
            return NotFound();
        }

        var postingResult = await _postingService.PostAsync(bill.Id, cancellationToken);
        if (!postingResult.Succeeded)
        {
            return BadRequest(postingResult.ErrorMessage);
        }

        var updatedBill = await _bills.GetByIdAsync(bill.Id, cancellationToken);
        return Ok(await ToDtoAsync(updatedBill!, cancellationToken));
    }

    private async Task<PurchaseBillDto> ToDtoAsync(PurchaseBill bill, CancellationToken cancellationToken)
    {
        var vendor = await _vendors.GetByIdAsync(bill.VendorId, cancellationToken);

        return new PurchaseBillDto(
            bill.Id,
            bill.BillNumber,
            bill.VendorId,
            vendor?.DisplayName,
            bill.BillDate,
            bill.DueDate,
            bill.Status,
            bill.TotalAmount,
            bill.PostedTransactionId,
            bill.PostedAt,
            bill.Lines.Select(line => new PurchaseBillLineDto(
                line.Id,
                line.ItemId,
                line.Description,
                line.Quantity,
                line.UnitCost,
                line.LineTotal)).ToList());
    }
}
