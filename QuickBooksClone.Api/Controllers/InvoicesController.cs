using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Contracts.Invoices;
using QuickBooksClone.Api.Contracts.Sales;
using QuickBooksClone.Api.Services;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Documents;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Core.Taxes;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/invoices")]
[RequirePermission("Sales.Invoice.Manage")]
public sealed class InvoicesController : ControllerBase
{
    private readonly IInvoiceRepository _invoices;
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly ISalesInvoicePostingService _postingService;
    private readonly SalesPostingPreviewService _previewService;
    private readonly SalesActivityService _activityService;
    private readonly IDocumentNumberService _documentNumbers;
    private readonly ICompanySettingsRepository _companySettings;
    private readonly ITaxCodeRepository _taxCodes;
    private readonly IDocumentMetadataService _metadata;

    public InvoicesController(
        IInvoiceRepository invoices,
        ICustomerRepository customers,
        IItemRepository items,
        IAccountRepository accounts,
        ISalesInvoicePostingService postingService,
        SalesPostingPreviewService previewService,
        SalesActivityService activityService,
        IDocumentNumberService documentNumbers,
        ICompanySettingsRepository companySettings,
        ITaxCodeRepository taxCodes,
        IDocumentMetadataService metadata)
    {
        _invoices = invoices;
        _customers = customers;
        _items = items;
        _accounts = accounts;
        _postingService = postingService;
        _previewService = previewService;
        _activityService = activityService;
        _documentNumbers = documentNumbers;
        _companySettings = companySettings;
        _taxCodes = taxCodes;
        _metadata = metadata;
    }

    [HttpGet]
    [ProducesResponseType(typeof(InvoiceListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<InvoiceListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] Guid? customerId,
        [FromQuery] bool includeVoid = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _invoices.SearchAsync(new InvoiceSearch(search, customerId, InvoicePaymentMode.Credit, includeVoid, page, pageSize), cancellationToken);
        var items = new List<InvoiceDto>();

        foreach (var invoice in result.Items)
        {
            items.Add(await ToDtoAsync(invoice, cancellationToken));
        }

        return Ok(new InvoiceListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("customers/{customerId:guid}/activity")]
    [ProducesResponseType(typeof(CustomerSalesActivityDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CustomerSalesActivityDto>> GetCustomerActivity(
        Guid customerId,
        [FromQuery] int limit = 5,
        CancellationToken cancellationToken = default)
    {
        var (activity, error) = await _activityService.GetCustomerActivityAsync(customerId, limit, cancellationToken);
        return error is not null ? BadRequest(error) : Ok(activity);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InvoiceDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoices.GetByIdAsync(id, cancellationToken);
        if (invoice is null || invoice.PaymentMode != InvoicePaymentMode.Credit)
        {
            return NotFound();
        }

        return Ok(await ToDtoAsync(invoice, cancellationToken));
    }

    [HttpGet("{id:guid}/notes")]
    [ProducesResponseType(typeof(InvoiceNotesResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InvoiceNotesResponse>> GetNotes(Guid id, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoices.GetByIdAsync(id, cancellationToken);
        if (invoice is null || invoice.PaymentMode != InvoicePaymentMode.Credit)
        {
            return NotFound();
        }

        var metadata = await _metadata.GetOrCreateAsync("invoice", id, cancellationToken);
        return Ok(new InvoiceNotesResponse(metadata.InternalNote ?? string.Empty));
    }

    [HttpPost("{id:guid}/notes")]
    [ProducesResponseType(typeof(InvoiceNotesResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InvoiceNotesResponse>> SaveNotes(Guid id, SaveInvoiceNotesRequest request, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoices.GetByIdAsync(id, cancellationToken);
        if (invoice is null || invoice.PaymentMode != InvoicePaymentMode.Credit)
        {
            return NotFound();
        }

        var current = await _metadata.GetOrCreateAsync("invoice", id, cancellationToken);
        var updated = await _metadata.UpdateAsync(
            "invoice",
            id,
            current.PublicMemo,
            request.Notes,
            current.ExternalReference,
            current.TemplateName,
            current.ShipToName,
            current.ShipToAddressLine1,
            current.ShipToAddressLine2,
            current.ShipToCity,
            current.ShipToRegion,
            current.ShipToPostalCode,
            current.ShipToCountry,
            cancellationToken);

        return Ok(new InvoiceNotesResponse(updated.InternalNote ?? string.Empty));
    }

    [HttpPost("preview")]
    [ProducesResponseType(typeof(SalesPostingPreviewDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<SalesPostingPreviewDto>> Preview(PreviewInvoiceRequest request, CancellationToken cancellationToken = default)
    {
        var (preview, error) = await _previewService.PreviewInvoiceAsync(request, cancellationToken);
        return error is not null ? BadRequest(error) : Ok(preview);
    }

    [HttpPost]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<InvoiceDto>> Create(CreateInvoiceRequest request, CancellationToken cancellationToken = default)
    {
        var saveMode = request.SaveMode == 0 ? InvoiceSaveMode.SaveAndPost : request.SaveMode;
        if (!Enum.IsDefined(saveMode))
        {
            return BadRequest("Invalid invoice save mode.");
        }

        var customer = await _customers.GetByIdAsync(request.CustomerId, cancellationToken);
        if (customer is null)
        {
            return BadRequest("Customer does not exist.");
        }

        if (!customer.IsActive)
        {
            return BadRequest("Cannot create an invoice for an inactive customer.");
        }

        if (request.DueDate < request.InvoiceDate)
        {
            return BadRequest("Invoice due date cannot be before invoice date.");
        }

        if (request.Lines.Count == 0)
        {
            return BadRequest("Invoice must have at least one line.");
        }

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.Invoice, cancellationToken);
        var taxSettings = await _companySettings.GetAsync(cancellationToken);
        var invoice = new Invoice(
            request.CustomerId,
            request.InvoiceDate,
            request.DueDate,
            null,
            allocation.DocumentNo);
        invoice.SetSyncIdentity(allocation.DeviceId, allocation.DocumentNo);

        foreach (var line in request.Lines)
        {
            var lineValidation = ValidateSalesLine(line.ItemId, line.Quantity, line.UnitPrice, line.DiscountPercent);
            if (lineValidation is not null)
            {
                return BadRequest(lineValidation);
            }

            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return BadRequest($"Item does not exist: {line.ItemId}");
            }

            if (!item.IsActive)
            {
                return BadRequest($"Cannot use inactive item on an invoice: {item.Name}");
            }

            if (item.ItemType == ItemType.Bundle)
            {
                return BadRequest($"Bundle item '{item.Name}' cannot be used until component posting is implemented.");
            }

            var unitPrice = line.UnitPrice > 0 ? line.UnitPrice : item.SalesPrice;
            var description = string.IsNullOrWhiteSpace(line.Description) ? item.Name : line.Description;
            TaxLineCalculation tax;
            try
            {
                tax = await ResolveTaxAsync(line.TaxCodeId, taxSettings, TaxTransactionType.Sales, unitPrice, line.Quantity, line.DiscountPercent, cancellationToken);
            }
            catch (InvalidOperationException exception)
            {
                return BadRequest(exception.Message);
            }

            invoice.AddLine(new InvoiceLine(item.Id, description, line.Quantity, tax.NetUnitPrice, line.DiscountPercent, taxCodeId: tax.TaxCodeId, taxRatePercent: tax.RatePercent, taxAmount: tax.TaxAmount));
        }

        await _invoices.AddAsync(invoice, cancellationToken);

        if (saveMode == InvoiceSaveMode.SaveAndPost)
        {
            var postingResult = await _postingService.PostAsync(invoice.Id, cancellationToken);
            if (!postingResult.Succeeded)
            {
                return BadRequest(postingResult.ErrorMessage);
            }
        }

        var savedInvoice = await _invoices.GetByIdAsync(invoice.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = invoice.Id }, await ToDtoAsync(savedInvoice!, cancellationToken));
    }

    [HttpPatch("{id:guid}/sent")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> MarkSent(Guid id, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoices.GetByIdAsync(id, cancellationToken);
        if (invoice is null || invoice.PaymentMode != InvoicePaymentMode.Credit)
        {
            return NotFound();
        }

        if (invoice.Status != InvoiceStatus.Draft)
        {
            return BadRequest("Only draft invoices can be marked as sent.");
        }

        var updated = await _invoices.MarkSentAsync(id, cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    [HttpPatch("{id:guid}/void")]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InvoiceDto>> Void(Guid id, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoices.GetByIdAsync(id, cancellationToken);
        if (invoice is null)
        {
            return NotFound();
        }

        var voidResult = await _postingService.VoidAsync(invoice.Id, cancellationToken);
        if (!voidResult.Succeeded)
        {
            return BadRequest(voidResult.ErrorMessage);
        }

        var updatedInvoice = await _invoices.GetByIdAsync(invoice.Id, cancellationToken);
        return Ok(await ToDtoAsync(updatedInvoice!, cancellationToken));
    }

    [HttpPost("{id:guid}/post")]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InvoiceDto>> Post(Guid id, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoices.GetByIdAsync(id, cancellationToken);
        if (invoice is null || invoice.PaymentMode != InvoicePaymentMode.Credit)
        {
            return NotFound();
        }

        var postingResult = await _postingService.PostAsync(invoice.Id, cancellationToken);
        if (!postingResult.Succeeded)
        {
            return BadRequest(postingResult.ErrorMessage);
        }

        var updatedInvoice = await _invoices.GetByIdAsync(invoice.Id, cancellationToken);
        return Ok(await ToDtoAsync(updatedInvoice!, cancellationToken));
    }

    private async Task<InvoiceDto> ToDtoAsync(Invoice invoice, CancellationToken cancellationToken)
    {
        var customer = await _customers.GetByIdAsync(invoice.CustomerId, cancellationToken);
        var depositAccount = invoice.DepositAccountId is null
            ? null
            : await _accounts.GetByIdAsync(invoice.DepositAccountId.Value, cancellationToken);

        return new InvoiceDto(
            invoice.Id,
            invoice.InvoiceNumber,
            invoice.CustomerId,
            customer?.DisplayName,
            invoice.SalesOrderId,
            invoice.InvoiceDate,
            invoice.DueDate,
            invoice.PaymentMode,
            invoice.DepositAccountId,
            depositAccount?.Name,
            invoice.PaymentMethod,
            invoice.ReceiptPaymentId,
            invoice.Status,
            invoice.Subtotal,
            invoice.DiscountAmount,
            invoice.TaxAmount,
            invoice.TotalAmount,
            invoice.PaidAmount,
            invoice.CreditAppliedAmount,
            invoice.ReturnedAmount,
            invoice.BalanceDue,
            invoice.PostedTransactionId,
            invoice.PostedAt,
            invoice.ReversalTransactionId,
            invoice.VoidedAt,
            invoice.Lines.Select(line => new InvoiceLineDto(
                line.Id,
                line.ItemId,
                line.SalesOrderLineId,
                line.Description,
                line.Quantity,
                line.UnitPrice,
                line.DiscountPercent,
                line.TaxCodeId,
                line.TaxRatePercent,
                line.TaxAmount,
                line.LineTotal)).ToList());
    }

    private static string? ValidateSalesLine(Guid itemId, decimal quantity, decimal unitPrice, decimal discountPercent)
    {
        if (itemId == Guid.Empty)
        {
            return "Line item is required.";
        }

        if (quantity <= 0)
        {
            return "Line quantity must be greater than zero.";
        }

        if (unitPrice < 0)
        {
            return "Line unit price cannot be negative.";
        }

        if (discountPercent is < 0 or > 100)
        {
            return "Line discount percent must be between 0 and 100.";
        }

        return null;
    }

    private async Task<TaxLineCalculation> ResolveTaxAsync(
        Guid? requestedTaxCodeId,
        QuickBooksClone.Core.Settings.CompanySettings? settings,
        TaxTransactionType transactionType,
        decimal unitPrice,
        decimal quantity,
        decimal discountPercent,
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
        if (!taxCode.IsActive || !taxCode.CanApplyTo(transactionType))
        {
            throw new InvalidOperationException("Tax code is not active or cannot be applied to this transaction type.");
        }

        var rate = taxCode.RatePercent;
        var grossLine = unitPrice * quantity;
        var discount = grossLine * (Math.Clamp(discountPercent, 0, 100) / 100);
        var taxableAmount = grossLine - discount;
        var netUnitPrice = unitPrice;

        if (settings.PricesIncludeTax && rate > 0)
        {
            var netLine = taxableAmount / (1 + rate / 100);
            netUnitPrice = quantity == 0 ? unitPrice : (grossLine - discount == 0 ? unitPrice : netLine / quantity);
            taxableAmount = netLine;
        }

        var taxAmount = Math.Round(taxableAmount * (rate / 100), 2, MidpointRounding.AwayFromZero);
        return new TaxLineCalculation(taxCode.Id, rate, taxAmount, netUnitPrice);
    }

    private sealed record TaxLineCalculation(Guid? TaxCodeId, decimal RatePercent, decimal TaxAmount, decimal NetUnitPrice);

    public sealed record InvoiceNotesResponse(string Notes);
    public sealed record SaveInvoiceNotesRequest(string Notes);
}
