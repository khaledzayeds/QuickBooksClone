using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.SalesReturns;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.SalesReturns;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/sales-returns")]
public sealed class SalesReturnsController : ControllerBase
{
    private readonly ISalesReturnRepository _salesReturns;
    private readonly IInvoiceRepository _invoices;
    private readonly ICustomerRepository _customers;
    private readonly ISalesReturnPostingService _postingService;

    public SalesReturnsController(
        ISalesReturnRepository salesReturns,
        IInvoiceRepository invoices,
        ICustomerRepository customers,
        ISalesReturnPostingService postingService)
    {
        _salesReturns = salesReturns;
        _invoices = invoices;
        _customers = customers;
        _postingService = postingService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(SalesReturnListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<SalesReturnListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] Guid? invoiceId,
        [FromQuery] Guid? customerId,
        [FromQuery] bool includeVoid = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _salesReturns.SearchAsync(new SalesReturnSearch(search, invoiceId, customerId, includeVoid, page, pageSize), cancellationToken);
        var items = new List<SalesReturnDto>();

        foreach (var salesReturn in result.Items)
        {
            items.Add(await ToDtoAsync(salesReturn, cancellationToken));
        }

        return Ok(new SalesReturnListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(SalesReturnDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SalesReturnDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var salesReturn = await _salesReturns.GetByIdAsync(id, cancellationToken);
        return salesReturn is null ? NotFound() : Ok(await ToDtoAsync(salesReturn, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(SalesReturnDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<SalesReturnDto>> Create(CreateSalesReturnRequest request, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoices.GetByIdAsync(request.InvoiceId, cancellationToken);
        if (invoice is null)
        {
            return BadRequest("Invoice does not exist.");
        }

        if (invoice.Status is InvoiceStatus.Draft or InvoiceStatus.Void)
        {
            return BadRequest("Cannot return a draft or void invoice.");
        }

        if (request.Lines.Count == 0)
        {
            return BadRequest("Sales return must have at least one line.");
        }

        var salesReturn = new SalesReturn(invoice.Id, invoice.CustomerId, request.ReturnDate);
        foreach (var requestLine in request.Lines)
        {
            var invoiceLine = invoice.Lines.FirstOrDefault(line => line.Id == requestLine.InvoiceLineId);
            if (invoiceLine is null)
            {
                return BadRequest($"Invoice line does not exist: {requestLine.InvoiceLineId}");
            }

            var unitPrice = requestLine.UnitPrice is > 0 ? requestLine.UnitPrice.Value : invoiceLine.UnitPrice;
            salesReturn.AddLine(new SalesReturnLine(
                invoiceLine.Id,
                invoiceLine.ItemId,
                invoiceLine.Description,
                requestLine.Quantity,
                unitPrice,
                requestLine.DiscountPercent));
        }

        await _salesReturns.AddAsync(salesReturn, cancellationToken);
        var postingResult = await _postingService.PostAsync(salesReturn.Id, cancellationToken);
        if (!postingResult.Succeeded)
        {
            return BadRequest(postingResult.ErrorMessage);
        }

        var savedReturn = await _salesReturns.GetByIdAsync(salesReturn.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = salesReturn.Id }, await ToDtoAsync(savedReturn!, cancellationToken));
    }

    [HttpPost("{id:guid}/post")]
    [ProducesResponseType(typeof(SalesReturnDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SalesReturnDto>> Post(Guid id, CancellationToken cancellationToken = default)
    {
        var salesReturn = await _salesReturns.GetByIdAsync(id, cancellationToken);
        if (salesReturn is null)
        {
            return NotFound();
        }

        var postingResult = await _postingService.PostAsync(salesReturn.Id, cancellationToken);
        if (!postingResult.Succeeded)
        {
            return BadRequest(postingResult.ErrorMessage);
        }

        var updatedReturn = await _salesReturns.GetByIdAsync(salesReturn.Id, cancellationToken);
        return Ok(await ToDtoAsync(updatedReturn!, cancellationToken));
    }

    private async Task<SalesReturnDto> ToDtoAsync(SalesReturn salesReturn, CancellationToken cancellationToken)
    {
        var invoice = await _invoices.GetByIdAsync(salesReturn.InvoiceId, cancellationToken);
        var customer = await _customers.GetByIdAsync(salesReturn.CustomerId, cancellationToken);

        return new SalesReturnDto(
            salesReturn.Id,
            salesReturn.ReturnNumber,
            salesReturn.InvoiceId,
            invoice?.InvoiceNumber,
            salesReturn.CustomerId,
            customer?.DisplayName,
            salesReturn.ReturnDate,
            salesReturn.Status,
            salesReturn.TotalAmount,
            salesReturn.PostedTransactionId,
            salesReturn.PostedAt,
            salesReturn.Lines.Select(line => new SalesReturnLineDto(
                line.Id,
                line.InvoiceLineId,
                line.ItemId,
                line.Description,
                line.Quantity,
                line.UnitPrice,
                line.DiscountPercent,
                line.LineTotal)).ToList());
    }
}
