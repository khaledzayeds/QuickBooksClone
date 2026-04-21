using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.PurchaseReturns;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.PurchaseReturns;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/purchase-returns")]
public sealed class PurchaseReturnsController : ControllerBase
{
    private readonly IPurchaseReturnRepository _returns;
    private readonly IPurchaseBillRepository _bills;
    private readonly IVendorRepository _vendors;
    private readonly IPurchaseReturnPostingService _postingService;
    private readonly IDocumentNumberService _documentNumbers;

    public PurchaseReturnsController(IPurchaseReturnRepository returns, IPurchaseBillRepository bills, IVendorRepository vendors, IPurchaseReturnPostingService postingService, IDocumentNumberService documentNumbers)
    {
        _returns = returns;
        _bills = bills;
        _vendors = vendors;
        _postingService = postingService;
        _documentNumbers = documentNumbers;
    }

    [HttpGet]
    public async Task<ActionResult<PurchaseReturnListResponse>> Search([FromQuery] string? search, [FromQuery] Guid? purchaseBillId, [FromQuery] Guid? vendorId, [FromQuery] bool includeVoid = false, [FromQuery] int page = 1, [FromQuery] int pageSize = 25, CancellationToken cancellationToken = default)
    {
        var result = await _returns.SearchAsync(new PurchaseReturnSearch(search, purchaseBillId, vendorId, includeVoid, page, pageSize), cancellationToken);
        var items = new List<PurchaseReturnDto>();
        foreach (var purchaseReturn in result.Items)
        {
            items.Add(await ToDtoAsync(purchaseReturn, cancellationToken));
        }

        return Ok(new PurchaseReturnListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<PurchaseReturnDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var purchaseReturn = await _returns.GetByIdAsync(id, cancellationToken);
        return purchaseReturn is null ? NotFound() : Ok(await ToDtoAsync(purchaseReturn, cancellationToken));
    }

    [HttpPost]
    public async Task<ActionResult<PurchaseReturnDto>> Create(CreatePurchaseReturnRequest request, CancellationToken cancellationToken = default)
    {
        var bill = await _bills.GetByIdAsync(request.PurchaseBillId, cancellationToken);
        if (bill is null) return BadRequest("Purchase bill does not exist.");
        if (bill.Status is PurchaseBillStatus.Draft or PurchaseBillStatus.Void) return BadRequest("Cannot return a draft or void purchase bill.");
        if (request.Lines.Count == 0) return BadRequest("Purchase return must have at least one line.");

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.PurchaseReturn, cancellationToken);
        var purchaseReturn = new PurchaseReturn(bill.Id, bill.VendorId, request.ReturnDate, allocation.DocumentNo);
        purchaseReturn.SetSyncIdentity(allocation.DeviceId, allocation.DocumentNo);
        foreach (var requestLine in request.Lines)
        {
            var billLine = bill.Lines.FirstOrDefault(line => line.Id == requestLine.PurchaseBillLineId);
            if (billLine is null) return BadRequest($"Purchase bill line does not exist: {requestLine.PurchaseBillLineId}");
            var unitCost = requestLine.UnitCost is > 0 ? requestLine.UnitCost.Value : billLine.UnitCost;
            purchaseReturn.AddLine(new PurchaseReturnLine(billLine.Id, billLine.ItemId, billLine.Description, requestLine.Quantity, unitCost));
        }

        await _returns.AddAsync(purchaseReturn, cancellationToken);
        var postingResult = await _postingService.PostAsync(purchaseReturn.Id, cancellationToken);
        if (!postingResult.Succeeded) return BadRequest(postingResult.ErrorMessage);

        var savedReturn = await _returns.GetByIdAsync(purchaseReturn.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = purchaseReturn.Id }, await ToDtoAsync(savedReturn!, cancellationToken));
    }

    private async Task<PurchaseReturnDto> ToDtoAsync(PurchaseReturn purchaseReturn, CancellationToken cancellationToken)
    {
        var bill = await _bills.GetByIdAsync(purchaseReturn.PurchaseBillId, cancellationToken);
        var vendor = await _vendors.GetByIdAsync(purchaseReturn.VendorId, cancellationToken);
        return new PurchaseReturnDto(
            purchaseReturn.Id,
            purchaseReturn.ReturnNumber,
            purchaseReturn.PurchaseBillId,
            bill?.BillNumber,
            purchaseReturn.VendorId,
            vendor?.DisplayName,
            purchaseReturn.ReturnDate,
            purchaseReturn.Status,
            purchaseReturn.TotalAmount,
            purchaseReturn.PostedTransactionId,
            purchaseReturn.PostedAt,
            purchaseReturn.Lines.Select(line => new PurchaseReturnLineDto(line.Id, line.PurchaseBillLineId, line.ItemId, line.Description, line.Quantity, line.UnitCost, line.LineTotal)).ToList());
    }
}
