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
    private readonly IAccountingTransactionRepository _transactions;

    public InvoicesController(
        IInvoiceRepository invoices,
        ICustomerRepository customers,
        IItemRepository items,
        IAccountRepository accounts,
        IAccountingTransactionRepository transactions)
    {
        _invoices = invoices;
        _customers = customers;
        _items = items;
        _accounts = accounts;
        _transactions = transactions;
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
        var result = await _invoices.SearchAsync(new InvoiceSearch(search, customerId, includeVoid, page, pageSize), cancellationToken);
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
        return invoice is null ? NotFound() : Ok(await ToDtoAsync(invoice, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<InvoiceDto>> Create(CreateInvoiceRequest request, CancellationToken cancellationToken = default)
    {
        var customer = await _customers.GetByIdAsync(request.CustomerId, cancellationToken);
        if (customer is null)
        {
            return BadRequest("Customer does not exist.");
        }

        if (request.Lines.Count == 0)
        {
            return BadRequest("Invoice must have at least one line.");
        }

        var invoice = new Invoice(request.CustomerId, request.InvoiceDate, request.DueDate);

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

        return CreatedAtAction(nameof(Get), new { id = invoice.Id }, await ToDtoAsync(invoice, cancellationToken));
    }

    [HttpPatch("{id:guid}/sent")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> MarkSent(Guid id, CancellationToken cancellationToken = default)
    {
        var updated = await _invoices.MarkSentAsync(id, cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    [HttpPatch("{id:guid}/void")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Void(Guid id, CancellationToken cancellationToken = default)
    {
        var updated = await _invoices.VoidAsync(id, cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    [HttpPost("{id:guid}/post")]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InvoiceDto>> Post(Guid id, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoices.GetByIdAsync(id, cancellationToken);
        if (invoice is null)
        {
            return NotFound();
        }

        if (invoice.PostedTransactionId is not null)
        {
            return BadRequest("Invoice is already posted.");
        }

        if (invoice.Status == InvoiceStatus.Void)
        {
            return BadRequest("Cannot post a void invoice.");
        }

        if (await _transactions.GetBySourceAsync("Invoice", invoice.Id, cancellationToken) is not null)
        {
            return BadRequest("Invoice already has a posted transaction.");
        }

        var arAccount = await FindFirstAccountAsync(AccountType.AccountsReceivable, cancellationToken);
        if (arAccount is null)
        {
            return BadRequest("Accounts Receivable account is missing.");
        }

        var transaction = new AccountingTransaction(
            "Invoice",
            invoice.InvoiceDate,
            invoice.InvoiceNumber,
            "Invoice",
            invoice.Id);

        transaction.AddLine(new AccountingTransactionLine(
            arAccount.Id,
            $"Invoice {invoice.InvoiceNumber}",
            invoice.TotalAmount,
            0));

        foreach (var line in invoice.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return BadRequest($"Item does not exist: {line.ItemId}");
            }

            if (item.IncomeAccountId is null)
            {
                return BadRequest($"Item '{item.Name}' is missing an income account.");
            }

            transaction.AddLine(new AccountingTransactionLine(
                item.IncomeAccountId.Value,
                line.Description,
                0,
                line.LineTotal));

            if (item.ItemType == ItemType.Inventory)
            {
                if (item.CogsAccountId is null || item.InventoryAssetAccountId is null)
                {
                    return BadRequest($"Inventory item '{item.Name}' is missing COGS or inventory asset account.");
                }

                var costAmount = item.PurchasePrice * line.Quantity;
                if (costAmount > 0)
                {
                    transaction.AddLine(new AccountingTransactionLine(
                        item.CogsAccountId.Value,
                        $"COGS - {line.Description}",
                        costAmount,
                        0));

                    transaction.AddLine(new AccountingTransactionLine(
                        item.InventoryAssetAccountId.Value,
                        $"Inventory relief - {line.Description}",
                        0,
                        costAmount));
                }
            }
        }

        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);
        await _invoices.MarkPostedAsync(invoice.Id, savedTransaction.Id, cancellationToken);

        var updatedInvoice = await _invoices.GetByIdAsync(invoice.Id, cancellationToken);
        return Ok(await ToDtoAsync(updatedInvoice!, cancellationToken));
    }

    private async Task<InvoiceDto> ToDtoAsync(Invoice invoice, CancellationToken cancellationToken)
    {
        var customer = await _customers.GetByIdAsync(invoice.CustomerId, cancellationToken);

        return new InvoiceDto(
            invoice.Id,
            invoice.InvoiceNumber,
            invoice.CustomerId,
            customer?.DisplayName,
            invoice.InvoiceDate,
            invoice.DueDate,
            invoice.Status,
            invoice.Subtotal,
            invoice.DiscountAmount,
            invoice.TaxAmount,
            invoice.TotalAmount,
            invoice.BalanceDue,
            invoice.PostedTransactionId,
            invoice.PostedAt,
            invoice.Lines.Select(line => new InvoiceLineDto(
                line.Id,
                line.ItemId,
                line.Description,
                line.Quantity,
                line.UnitPrice,
                line.DiscountPercent,
                line.LineTotal)).ToList());
    }

    private async Task<Account?> FindFirstAccountAsync(AccountType accountType, CancellationToken cancellationToken)
    {
        var result = await _accounts.SearchAsync(new AccountSearch(null, accountType, false, 1, 1), cancellationToken);
        return result.Items.FirstOrDefault();
    }
}
