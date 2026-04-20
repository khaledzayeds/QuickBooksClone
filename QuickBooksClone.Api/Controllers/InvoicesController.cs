using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Invoices;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/invoices")]
public sealed class InvoicesController : ControllerBase
{
    private readonly IInvoiceRepository _invoices;
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly ISalesInvoicePostingService _postingService;

    public InvoicesController(
        IInvoiceRepository invoices,
        ICustomerRepository customers,
        IItemRepository items,
        IAccountRepository accounts,
        ISalesInvoicePostingService postingService)
    {
        _invoices = invoices;
        _customers = customers;
        _items = items;
        _accounts = accounts;
        _postingService = postingService;
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

        if (request.Lines.Count == 0)
        {
            return BadRequest("Invoice must have at least one line.");
        }

        var invoice = new Invoice(
            request.CustomerId,
            request.InvoiceDate,
            request.DueDate);

        foreach (var line in request.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return BadRequest($"Item does not exist: {line.ItemId}");
            }

            var unitPrice = line.UnitPrice > 0 ? line.UnitPrice : item.SalesPrice;
            var description = string.IsNullOrWhiteSpace(line.Description) ? item.Name : line.Description;
            invoice.AddLine(new InvoiceLine(item.Id, description, line.Quantity, unitPrice, line.DiscountPercent));
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
                line.Description,
                line.Quantity,
                line.UnitPrice,
                line.DiscountPercent,
                line.LineTotal)).ToList());
    }

}
