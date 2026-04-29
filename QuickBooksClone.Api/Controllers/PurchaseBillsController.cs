using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Contracts.PurchaseBills;
using QuickBooksClone.Api.Contracts.PurchaseWorkflow;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.ReceiveInventory;
using QuickBooksClone.Core.PurchaseWorkflow;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Core.Taxes;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/purchase-bills")]
[RequirePermission("Purchases.Bill.Manage")]
public sealed class PurchaseBillsController : ControllerBase
{
    private readonly IPurchaseBillRepository _bills;
    private readonly IVendorRepository _vendors;
    private readonly IItemRepository _items;
    private readonly IInventoryReceiptRepository _receipts;
    private readonly IPurchaseBillPostingService _postingService;
    private readonly IDocumentNumberService _documentNumbers;
    private readonly IPurchaseWorkflowService _workflow;
    private readonly ICompanySettingsRepository _companySettings;
    private readonly ITaxCodeRepository _taxCodes;

    public PurchaseBillsController(
        IPurchaseBillRepository bills,
        IVendorRepository vendors,
        IItemRepository items,
        IInventoryReceiptRepository receipts,
        IPurchaseBillPostingService postingService,
        IDocumentNumberService documentNumbers,
        IPurchaseWorkflowService workflow,
        ICompanySettingsRepository companySettings,
        ITaxCodeRepository taxCodes)
    {
        _bills = bills;
        _vendors = vendors;
        _items = items;
        _receipts = receipts;
        _postingService = postingService;
        _documentNumbers = documentNumbers;
        _workflow = workflow;
        _companySettings = companySettings;
        _taxCodes = taxCodes;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PurchaseBillListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<PurchaseBillListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] Guid? vendorId,
        [FromQuery] Guid? inventoryReceiptId,
        [FromQuery] bool includeVoid = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _bills.SearchAsync(new PurchaseBillSearch(search, vendorId, inventoryReceiptId, includeVoid, page, pageSize), cancellationToken);
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

    [HttpGet("{id:guid}/payment-plan")]
    [ProducesResponseType(typeof(PurchaseBillPaymentPlanDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PurchaseBillPaymentPlanDto>> GetPaymentPlan(Guid id, CancellationToken cancellationToken = default)
    {
        var plan = await _workflow.GetPaymentPlanAsync(id, cancellationToken);
        if (plan is null)
        {
            return NotFound();
        }

        var vendor = await _vendors.GetByIdAsync(plan.VendorId, cancellationToken);
        return Ok(new PurchaseBillPaymentPlanDto(
            plan.PurchaseBillId,
            plan.BillNumber,
            plan.VendorId,
            vendor?.DisplayName,
            plan.Status,
            plan.CanPay,
            plan.IsFullyPaid,
            plan.TotalAmount,
            plan.PaidAmount,
            plan.CreditAppliedAmount,
            plan.ReturnedAmount,
            plan.BalanceDue,
            plan.LinkedPayments.Select(payment => new LinkedVendorPaymentReferenceDto(
                payment.Id,
                payment.PaymentNumber,
                payment.PaymentDate,
                payment.Status,
                payment.Amount)).ToList()));
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

        InventoryReceipt? receipt = null;
        Dictionary<Guid, decimal> alreadyBilled = [];
        if (request.InventoryReceiptId is not null)
        {
            receipt = await _receipts.GetByIdAsync(request.InventoryReceiptId.Value, cancellationToken);
            if (receipt is null)
            {
                return BadRequest("Inventory receipt does not exist.");
            }

            if (receipt.VendorId != request.VendorId)
            {
                return BadRequest("Inventory receipt vendor does not match the selected vendor.");
            }

            if (receipt.Status != InventoryReceiptStatus.Posted)
            {
                return BadRequest("Only posted inventory receipts can be billed.");
            }

            alreadyBilled = await _bills.GetBilledQuantitiesByInventoryReceiptLineIdsAsync(receipt.Lines.Select(line => line.Id), cancellationToken);
        }

        var requestedQuantitiesByReceiptLine = request.Lines
            .Where(line => line.InventoryReceiptLineId.HasValue)
            .GroupBy(line => line.InventoryReceiptLineId!.Value)
            .ToDictionary(group => group.Key, group => group.Sum(line => line.Quantity));

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.PurchaseBill, cancellationToken);
        var taxSettings = await _companySettings.GetAsync(cancellationToken);
        var bill = new PurchaseBill(request.VendorId, request.BillDate, request.DueDate, allocation.DocumentNo);
        bill.SetSyncIdentity(allocation.DeviceId, allocation.DocumentNo);
        if (receipt is not null)
        {
            bill.LinkInventoryReceipt(receipt.Id);
        }

        foreach (var line in request.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return BadRequest($"Item does not exist: {line.ItemId}");
            }

            Guid? inventoryReceiptLineId = null;
            if (receipt is not null)
            {
                if (line.InventoryReceiptLineId is null || line.InventoryReceiptLineId == Guid.Empty)
                {
                    return BadRequest("Every billed line must reference an inventory receipt line when an inventory receipt is selected.");
                }

                var receiptLine = receipt.Lines.FirstOrDefault(current => current.Id == line.InventoryReceiptLineId.Value);
                if (receiptLine is null)
                {
                    return BadRequest($"Inventory receipt line does not exist on the selected receipt: {line.InventoryReceiptLineId}");
                }

                if (receiptLine.ItemId != line.ItemId)
                {
                    return BadRequest("Inventory receipt line item does not match the billed item.");
                }

                var already = alreadyBilled.GetValueOrDefault(receiptLine.Id);
                var requested = requestedQuantitiesByReceiptLine.GetValueOrDefault(receiptLine.Id);
                if (already + requested > receiptLine.Quantity)
                {
                    return BadRequest($"Billed quantity exceeds received quantity for '{item.Name}'. Received: {receiptLine.Quantity:N2}, already billed: {already:N2}, requested now: {requested:N2}.");
                }

                inventoryReceiptLineId = receiptLine.Id;
            }
            else if (line.InventoryReceiptLineId is not null)
            {
                return BadRequest("Cannot specify inventory receipt line without selecting an inventory receipt.");
            }

            var unitCost = line.UnitCost > 0 ? line.UnitCost : item.PurchasePrice;
            var description = string.IsNullOrWhiteSpace(line.Description) ? item.Name : line.Description;
            TaxLineCalculation tax;
            try
            {
                tax = await ResolveTaxAsync(line.TaxCodeId, taxSettings, unitCost, line.Quantity, cancellationToken);
            }
            catch (InvalidOperationException exception)
            {
                return BadRequest(exception.Message);
            }

            bill.AddLine(new PurchaseBillLine(item.Id, description, line.Quantity, tax.NetUnitCost, inventoryReceiptLineId, taxCodeId: tax.TaxCodeId, taxRatePercent: tax.RatePercent, taxAmount: tax.TaxAmount));
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

    [HttpPatch("{id:guid}/void")]
    [ProducesResponseType(typeof(PurchaseBillDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PurchaseBillDto>> Void(Guid id, CancellationToken cancellationToken = default)
    {
        var bill = await _bills.GetByIdAsync(id, cancellationToken);
        if (bill is null)
        {
            return NotFound();
        }

        var voidResult = await _postingService.VoidAsync(bill.Id, cancellationToken);
        if (!voidResult.Succeeded)
        {
            return BadRequest(voidResult.ErrorMessage);
        }

        var updatedBill = await _bills.GetByIdAsync(bill.Id, cancellationToken);
        return Ok(await ToDtoAsync(updatedBill!, cancellationToken));
    }

    private async Task<PurchaseBillDto> ToDtoAsync(PurchaseBill bill, CancellationToken cancellationToken)
    {
        var vendor = await _vendors.GetByIdAsync(bill.VendorId, cancellationToken);
        var receipt = bill.InventoryReceiptId is null ? null : await _receipts.GetByIdAsync(bill.InventoryReceiptId.Value, cancellationToken);

        return new PurchaseBillDto(
            bill.Id,
            bill.BillNumber,
            bill.VendorId,
            vendor?.DisplayName,
            bill.InventoryReceiptId,
            receipt?.ReceiptNumber,
            bill.BillDate,
            bill.DueDate,
            bill.Status,
            bill.TaxAmount,
            bill.TotalAmount,
            bill.PaidAmount,
            bill.CreditAppliedAmount,
            bill.ReturnedAmount,
            bill.BalanceDue,
            bill.PostedTransactionId,
            bill.PostedAt,
            bill.ReversalTransactionId,
            bill.VoidedAt,
            bill.Lines.Select(line => new PurchaseBillLineDto(
                line.Id,
                line.ItemId,
                line.InventoryReceiptLineId,
                line.Description,
                line.Quantity,
                line.UnitCost,
                line.TaxCodeId,
                line.TaxRatePercent,
                line.TaxAmount,
                line.LineTotal)).ToList());
    }

    private async Task<TaxLineCalculation> ResolveTaxAsync(
        Guid? requestedTaxCodeId,
        QuickBooksClone.Core.Settings.CompanySettings? settings,
        decimal unitCost,
        decimal quantity,
        CancellationToken cancellationToken)
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

    private sealed record TaxLineCalculation(Guid? TaxCodeId, decimal RatePercent, decimal TaxAmount, decimal NetUnitCost);
}
