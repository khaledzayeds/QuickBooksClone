using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Invoices;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.Payments;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/invoices")]
public sealed class InvoicesController : ControllerBase
{
    private readonly IInvoiceRepository _invoices;
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly IPaymentRepository _payments;
    private readonly ISalesInvoicePostingService _postingService;
    private readonly IPaymentPostingService _paymentPostingService;

    public InvoicesController(
        IInvoiceRepository invoices,
        ICustomerRepository customers,
        IItemRepository items,
        IAccountRepository accounts,
        IPaymentRepository payments,
        ISalesInvoicePostingService postingService,
        IPaymentPostingService paymentPostingService)
    {
        _invoices = invoices;
        _customers = customers;
        _items = items;
        _accounts = accounts;
        _payments = payments;
        _postingService = postingService;
        _paymentPostingService = paymentPostingService;
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
        var saveMode = request.SaveMode == 0 ? InvoiceSaveMode.SaveAndPost : request.SaveMode;
        if (!Enum.IsDefined(saveMode))
        {
            return BadRequest("Invalid invoice save mode.");
        }

        var paymentMode = request.PaymentMode == 0 ? InvoicePaymentMode.Credit : request.PaymentMode;
        if (!Enum.IsDefined(paymentMode))
        {
            return BadRequest("Invalid invoice payment mode.");
        }

        var customer = await _customers.GetByIdAsync(request.CustomerId, cancellationToken);
        if (customer is null)
        {
            return BadRequest("Customer does not exist.");
        }

        if (paymentMode == InvoicePaymentMode.Cash)
        {
            var depositValidation = await ValidateDepositAccountAsync(request.DepositAccountId, cancellationToken);
            if (depositValidation is not null)
            {
                return BadRequest(depositValidation);
            }
        }

        if (request.Lines.Count == 0)
        {
            return BadRequest("Invoice must have at least one line.");
        }

        var invoice = new Invoice(
            request.CustomerId,
            request.InvoiceDate,
            request.DueDate,
            paymentMode: paymentMode,
            depositAccountId: paymentMode == InvoicePaymentMode.Cash ? request.DepositAccountId : null,
            paymentMethod: paymentMode == InvoicePaymentMode.Cash ? request.PaymentMethod ?? "Cash" : null);

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
            var workflowValidation = await PostInvoiceAndAutoReceiveIfNeededAsync(invoice.Id, cancellationToken);
            if (workflowValidation is not null)
            {
                return BadRequest(workflowValidation);
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
        if (invoice is null)
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
        if (invoice is null)
        {
            return NotFound();
        }

        var workflowValidation = await PostInvoiceAndAutoReceiveIfNeededAsync(invoice.Id, cancellationToken);
        if (workflowValidation is not null)
        {
            return BadRequest(workflowValidation);
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

    private async Task<string?> PostInvoiceAndAutoReceiveIfNeededAsync(Guid invoiceId, CancellationToken cancellationToken)
    {
        var postingResult = await _postingService.PostAsync(invoiceId, cancellationToken);
        if (!postingResult.Succeeded)
        {
            return postingResult.ErrorMessage;
        }

        var invoice = await _invoices.GetByIdAsync(invoiceId, cancellationToken);
        if (invoice is null)
        {
            return "Invoice does not exist.";
        }

        if (invoice.PaymentMode != InvoicePaymentMode.Cash || invoice.BalanceDue <= 0 || invoice.ReceiptPaymentId is not null)
        {
            return null;
        }

        var depositValidation = await ValidateDepositAccountAsync(invoice.DepositAccountId, cancellationToken);
        if (depositValidation is not null)
        {
            return depositValidation;
        }

        var payment = new Payment(
            invoice.CustomerId,
            invoice.Id,
            invoice.DepositAccountId!.Value,
            invoice.InvoiceDate,
            invoice.BalanceDue,
            invoice.PaymentMethod ?? "Cash",
            $"RCPT-{invoice.InvoiceNumber}");

        await _payments.AddAsync(payment, cancellationToken);

        var paymentResult = await _paymentPostingService.PostAsync(payment.Id, cancellationToken);
        if (!paymentResult.Succeeded)
        {
            return paymentResult.ErrorMessage;
        }

        await _invoices.LinkReceiptPaymentAsync(invoice.Id, payment.Id, cancellationToken);
        return null;
    }

    private async Task<string?> ValidateDepositAccountAsync(Guid? depositAccountId, CancellationToken cancellationToken)
    {
        if (depositAccountId is null || depositAccountId == Guid.Empty)
        {
            return "Deposit account is required for cash invoices.";
        }

        var depositAccount = await _accounts.GetByIdAsync(depositAccountId.Value, cancellationToken);
        if (depositAccount is null)
        {
            return "Deposit account does not exist.";
        }

        if (depositAccount.AccountType is not AccountType.Bank and not AccountType.OtherCurrentAsset)
        {
            return "Deposit account must be a bank or other current asset account.";
        }

        return null;
    }
}
