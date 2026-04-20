using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Invoices;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.Payments;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/sales-receipts")]
public sealed class SalesReceiptsController : ControllerBase
{
    private readonly IInvoiceRepository _invoices;
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly IPaymentRepository _payments;
    private readonly ISalesInvoicePostingService _postingService;
    private readonly IPaymentPostingService _paymentPostingService;

    public SalesReceiptsController(
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
        var result = await _invoices.SearchAsync(new InvoiceSearch(search, customerId, InvoicePaymentMode.Cash, includeVoid, page, pageSize), cancellationToken);
        var items = new List<InvoiceDto>();

        foreach (var receipt in result.Items)
        {
            items.Add(await ToDtoAsync(receipt, cancellationToken));
        }

        return Ok(new InvoiceListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InvoiceDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var receipt = await _invoices.GetByIdAsync(id, cancellationToken);
        if (receipt is null || receipt.PaymentMode != InvoicePaymentMode.Cash)
        {
            return NotFound();
        }

        return Ok(await ToDtoAsync(receipt, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<InvoiceDto>> Create(CreateSalesReceiptRequest request, CancellationToken cancellationToken = default)
    {
        var customer = await _customers.GetByIdAsync(request.CustomerId, cancellationToken);
        if (customer is null)
        {
            return BadRequest("Customer does not exist.");
        }

        if (request.Lines.Count == 0)
        {
            return BadRequest("Sales receipt must have at least one line.");
        }

        var depositValidation = await ValidateDepositAccountAsync(request.DepositAccountId, cancellationToken);
        if (depositValidation is not null)
        {
            return BadRequest(depositValidation);
        }

        var receipt = new Invoice(
            request.CustomerId,
            request.ReceiptDate,
            request.ReceiptDate,
            paymentMode: InvoicePaymentMode.Cash,
            depositAccountId: request.DepositAccountId,
            paymentMethod: request.PaymentMethod ?? "Cash");

        foreach (var line in request.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return BadRequest($"Item does not exist: {line.ItemId}");
            }

            if (!item.IsActive)
            {
                return BadRequest($"Cannot use inactive item on a sales receipt: {item.Name}");
            }

            var unitPrice = line.UnitPrice > 0 ? line.UnitPrice : item.SalesPrice;
            var description = string.IsNullOrWhiteSpace(line.Description) ? item.Name : line.Description;
            receipt.AddLine(new InvoiceLine(item.Id, description, line.Quantity, unitPrice, line.DiscountPercent));
        }

        await _invoices.AddAsync(receipt, cancellationToken);

        var workflowValidation = await PostSalesReceiptAsync(receipt.Id, cancellationToken);
        if (workflowValidation is not null)
        {
            return BadRequest(workflowValidation);
        }

        var savedReceipt = await _invoices.GetByIdAsync(receipt.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = receipt.Id }, await ToDtoAsync(savedReceipt!, cancellationToken));
    }

    [HttpPatch("{id:guid}/void")]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InvoiceDto>> Void(Guid id, CancellationToken cancellationToken = default)
    {
        var receipt = await _invoices.GetByIdAsync(id, cancellationToken);
        if (receipt is null || receipt.PaymentMode != InvoicePaymentMode.Cash)
        {
            return NotFound();
        }

        if (receipt.ReceiptPaymentId is not null)
        {
            var payment = await _payments.GetByIdAsync(receipt.ReceiptPaymentId.Value, cancellationToken);
            if (payment is not null && payment.Status != PaymentStatus.Void)
            {
                var voidPaymentResult = await _paymentPostingService.VoidAsync(payment.Id, cancellationToken);
                if (!voidPaymentResult.Succeeded)
                {
                    return BadRequest(voidPaymentResult.ErrorMessage);
                }
            }
        }

        var voidResult = await _postingService.VoidAsync(receipt.Id, cancellationToken);
        if (!voidResult.Succeeded)
        {
            return BadRequest(voidResult.ErrorMessage);
        }

        var updatedReceipt = await _invoices.GetByIdAsync(receipt.Id, cancellationToken);
        return Ok(await ToDtoAsync(updatedReceipt!, cancellationToken));
    }

    private async Task<InvoiceDto> ToDtoAsync(Invoice receipt, CancellationToken cancellationToken)
    {
        var customer = await _customers.GetByIdAsync(receipt.CustomerId, cancellationToken);
        var depositAccount = receipt.DepositAccountId is null
            ? null
            : await _accounts.GetByIdAsync(receipt.DepositAccountId.Value, cancellationToken);

        return new InvoiceDto(
            receipt.Id,
            receipt.InvoiceNumber,
            receipt.CustomerId,
            customer?.DisplayName,
            receipt.InvoiceDate,
            receipt.DueDate,
            receipt.PaymentMode,
            receipt.DepositAccountId,
            depositAccount?.Name,
            receipt.PaymentMethod,
            receipt.ReceiptPaymentId,
            receipt.Status,
            receipt.Subtotal,
            receipt.DiscountAmount,
            receipt.TaxAmount,
            receipt.TotalAmount,
            receipt.PaidAmount,
            receipt.CreditAppliedAmount,
            receipt.ReturnedAmount,
            receipt.BalanceDue,
            receipt.PostedTransactionId,
            receipt.PostedAt,
            receipt.ReversalTransactionId,
            receipt.VoidedAt,
            receipt.Lines.Select(line => new InvoiceLineDto(
                line.Id,
                line.ItemId,
                line.Description,
                line.Quantity,
                line.UnitPrice,
                line.DiscountPercent,
                line.LineTotal)).ToList());
    }

    private async Task<string?> PostSalesReceiptAsync(Guid receiptId, CancellationToken cancellationToken)
    {
        var postingResult = await _postingService.PostAsync(receiptId, cancellationToken);
        if (!postingResult.Succeeded)
        {
            return postingResult.ErrorMessage;
        }

        var receipt = await _invoices.GetByIdAsync(receiptId, cancellationToken);
        if (receipt is null)
        {
            return "Sales receipt does not exist.";
        }

        if (receipt.BalanceDue <= 0 || receipt.ReceiptPaymentId is not null || receipt.DepositAccountId is null)
        {
            return null;
        }

        var payment = new Payment(
            receipt.CustomerId,
            receipt.Id,
            receipt.DepositAccountId.Value,
            receipt.InvoiceDate,
            receipt.BalanceDue,
            receipt.PaymentMethod ?? "Cash",
            $"RCPT-{receipt.InvoiceNumber}");

        await _payments.AddAsync(payment, cancellationToken);

        var paymentResult = await _paymentPostingService.PostAsync(payment.Id, cancellationToken);
        if (!paymentResult.Succeeded)
        {
            return paymentResult.ErrorMessage;
        }

        await _invoices.LinkReceiptPaymentAsync(receipt.Id, payment.Id, cancellationToken);
        return null;
    }

    private async Task<string?> ValidateDepositAccountAsync(Guid depositAccountId, CancellationToken cancellationToken)
    {
        if (depositAccountId == Guid.Empty)
        {
            return "Deposit account is required for sales receipts.";
        }

        var depositAccount = await _accounts.GetByIdAsync(depositAccountId, cancellationToken);
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
