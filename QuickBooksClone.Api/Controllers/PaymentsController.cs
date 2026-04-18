using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Payments;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Payments;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/payments")]
public sealed class PaymentsController : ControllerBase
{
    private readonly IPaymentRepository _payments;
    private readonly IInvoiceRepository _invoices;
    private readonly ICustomerRepository _customers;
    private readonly IAccountRepository _accounts;
    private readonly IPaymentPostingService _postingService;

    public PaymentsController(
        IPaymentRepository payments,
        IInvoiceRepository invoices,
        ICustomerRepository customers,
        IAccountRepository accounts,
        IPaymentPostingService postingService)
    {
        _payments = payments;
        _invoices = invoices;
        _customers = customers;
        _accounts = accounts;
        _postingService = postingService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PaymentListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<PaymentListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] Guid? customerId,
        [FromQuery] Guid? invoiceId,
        [FromQuery] bool includeVoid = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _payments.SearchAsync(new PaymentSearch(search, customerId, invoiceId, includeVoid, page, pageSize), cancellationToken);
        var items = new List<PaymentDto>();

        foreach (var payment in result.Items)
        {
            items.Add(await ToDtoAsync(payment, cancellationToken));
        }

        return Ok(new PaymentListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(PaymentDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PaymentDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var payment = await _payments.GetByIdAsync(id, cancellationToken);
        return payment is null ? NotFound() : Ok(await ToDtoAsync(payment, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(PaymentDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PaymentDto>> Create(CreatePaymentRequest request, CancellationToken cancellationToken = default)
    {
        if (request.Amount <= 0)
        {
            return BadRequest("Payment amount must be greater than zero.");
        }

        var invoice = await _invoices.GetByIdAsync(request.InvoiceId, cancellationToken);
        if (invoice is null)
        {
            return BadRequest("Invoice does not exist.");
        }

        if (invoice.Status is InvoiceStatus.Draft or InvoiceStatus.Void)
        {
            return BadRequest("Cannot receive a payment for a draft or void invoice.");
        }

        if (request.Amount > invoice.BalanceDue)
        {
            return BadRequest($"Payment amount exceeds invoice balance. Balance due: {invoice.BalanceDue:N2}.");
        }

        var depositAccount = await _accounts.GetByIdAsync(request.DepositAccountId, cancellationToken);
        if (depositAccount is null)
        {
            return BadRequest("Deposit account does not exist.");
        }

        if (depositAccount.AccountType is not AccountType.Bank and not AccountType.OtherCurrentAsset)
        {
            return BadRequest("Deposit account must be a bank or other current asset account.");
        }

        var payment = new Payment(
            invoice.CustomerId,
            invoice.Id,
            request.DepositAccountId,
            request.PaymentDate,
            request.Amount,
            request.PaymentMethod ?? "Cash");

        await _payments.AddAsync(payment, cancellationToken);

        var postingResult = await _postingService.PostAsync(payment.Id, cancellationToken);
        if (!postingResult.Succeeded)
        {
            return BadRequest(postingResult.ErrorMessage);
        }

        var savedPayment = await _payments.GetByIdAsync(payment.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = payment.Id }, await ToDtoAsync(savedPayment!, cancellationToken));
    }

    private async Task<PaymentDto> ToDtoAsync(Payment payment, CancellationToken cancellationToken)
    {
        var customer = await _customers.GetByIdAsync(payment.CustomerId, cancellationToken);
        var invoice = await _invoices.GetByIdAsync(payment.InvoiceId, cancellationToken);
        var depositAccount = await _accounts.GetByIdAsync(payment.DepositAccountId, cancellationToken);

        return new PaymentDto(
            payment.Id,
            payment.PaymentNumber,
            payment.CustomerId,
            customer?.DisplayName,
            payment.InvoiceId,
            invoice?.InvoiceNumber,
            payment.DepositAccountId,
            depositAccount?.Name,
            payment.PaymentDate,
            payment.Amount,
            payment.PaymentMethod,
            payment.Status,
            payment.PostedTransactionId,
            payment.PostedAt);
    }
}
