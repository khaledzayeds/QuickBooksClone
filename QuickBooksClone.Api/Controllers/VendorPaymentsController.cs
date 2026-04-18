using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.VendorPayments;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.VendorPayments;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/vendor-payments")]
public sealed class VendorPaymentsController : ControllerBase
{
    private readonly IVendorPaymentRepository _payments;
    private readonly IPurchaseBillRepository _bills;
    private readonly IVendorRepository _vendors;
    private readonly IAccountRepository _accounts;
    private readonly IVendorPaymentPostingService _postingService;

    public VendorPaymentsController(
        IVendorPaymentRepository payments,
        IPurchaseBillRepository bills,
        IVendorRepository vendors,
        IAccountRepository accounts,
        IVendorPaymentPostingService postingService)
    {
        _payments = payments;
        _bills = bills;
        _vendors = vendors;
        _accounts = accounts;
        _postingService = postingService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(VendorPaymentListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<VendorPaymentListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] Guid? vendorId,
        [FromQuery] Guid? purchaseBillId,
        [FromQuery] bool includeVoid = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _payments.SearchAsync(new VendorPaymentSearch(search, vendorId, purchaseBillId, includeVoid, page, pageSize), cancellationToken);
        var items = new List<VendorPaymentDto>();

        foreach (var payment in result.Items)
        {
            items.Add(await ToDtoAsync(payment, cancellationToken));
        }

        return Ok(new VendorPaymentListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(VendorPaymentDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<VendorPaymentDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var payment = await _payments.GetByIdAsync(id, cancellationToken);
        return payment is null ? NotFound() : Ok(await ToDtoAsync(payment, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(VendorPaymentDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<VendorPaymentDto>> Create(CreateVendorPaymentRequest request, CancellationToken cancellationToken = default)
    {
        if (request.Amount <= 0)
        {
            return BadRequest("Vendor payment amount must be greater than zero.");
        }

        var bill = await _bills.GetByIdAsync(request.PurchaseBillId, cancellationToken);
        if (bill is null)
        {
            return BadRequest("Purchase bill does not exist.");
        }

        if (bill.Status is PurchaseBillStatus.Draft or PurchaseBillStatus.Void)
        {
            return BadRequest("Cannot pay a draft or void purchase bill.");
        }

        if (request.Amount > bill.BalanceDue)
        {
            return BadRequest($"Vendor payment exceeds purchase bill balance. Balance due: {bill.BalanceDue:N2}.");
        }

        var paymentAccount = await _accounts.GetByIdAsync(request.PaymentAccountId, cancellationToken);
        if (paymentAccount is null)
        {
            return BadRequest("Payment account does not exist.");
        }

        if (paymentAccount.AccountType is not AccountType.Bank and not AccountType.OtherCurrentAsset)
        {
            return BadRequest("Payment account must be a bank or other current asset account.");
        }

        var payment = new VendorPayment(
            bill.VendorId,
            bill.Id,
            request.PaymentAccountId,
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

    [HttpPatch("{id:guid}/void")]
    [ProducesResponseType(typeof(VendorPaymentDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<VendorPaymentDto>> Void(Guid id, CancellationToken cancellationToken = default)
    {
        var payment = await _payments.GetByIdAsync(id, cancellationToken);
        if (payment is null)
        {
            return NotFound();
        }

        var voidResult = await _postingService.VoidAsync(payment.Id, cancellationToken);
        if (!voidResult.Succeeded)
        {
            return BadRequest(voidResult.ErrorMessage);
        }

        var updatedPayment = await _payments.GetByIdAsync(payment.Id, cancellationToken);
        return Ok(await ToDtoAsync(updatedPayment!, cancellationToken));
    }

    private async Task<VendorPaymentDto> ToDtoAsync(VendorPayment payment, CancellationToken cancellationToken)
    {
        var vendor = await _vendors.GetByIdAsync(payment.VendorId, cancellationToken);
        var bill = await _bills.GetByIdAsync(payment.PurchaseBillId, cancellationToken);
        var paymentAccount = await _accounts.GetByIdAsync(payment.PaymentAccountId, cancellationToken);

        return new VendorPaymentDto(
            payment.Id,
            payment.PaymentNumber,
            payment.VendorId,
            vendor?.DisplayName,
            payment.PurchaseBillId,
            bill?.BillNumber,
            payment.PaymentAccountId,
            paymentAccount?.Name,
            payment.PaymentDate,
            payment.Amount,
            payment.PaymentMethod,
            payment.Status,
            payment.PostedTransactionId,
            payment.PostedAt,
            payment.ReversalTransactionId,
            payment.VoidedAt);
    }
}
