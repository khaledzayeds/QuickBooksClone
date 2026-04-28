using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Contracts.CustomerCredits;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.CustomerCredits;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/customer-credits")]
[RequirePermission("Sales.Return.Manage")]
public sealed class CustomerCreditsController : ControllerBase
{
    private readonly ICustomerCreditActivityRepository _activities;
    private readonly ICustomerCreditPostingService _postingService;
    private readonly ICustomerRepository _customers;
    private readonly IInvoiceRepository _invoices;
    private readonly IAccountRepository _accounts;
    private readonly IDocumentNumberService _documentNumbers;

    public CustomerCreditsController(
        ICustomerCreditActivityRepository activities,
        ICustomerCreditPostingService postingService,
        ICustomerRepository customers,
        IInvoiceRepository invoices,
        IAccountRepository accounts,
        IDocumentNumberService documentNumbers)
    {
        _activities = activities;
        _postingService = postingService;
        _customers = customers;
        _invoices = invoices;
        _accounts = accounts;
        _documentNumbers = documentNumbers;
    }

    [HttpGet]
    [ProducesResponseType(typeof(CustomerCreditActivityListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<CustomerCreditActivityListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] Guid? customerId,
        [FromQuery] CustomerCreditAction? action,
        [FromQuery] bool includeVoid = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _activities.SearchAsync(new CustomerCreditActivitySearch(search, customerId, action, includeVoid, page, pageSize), cancellationToken);
        var items = new List<CustomerCreditActivityDto>();

        foreach (var activity in result.Items)
        {
            items.Add(await ToDtoAsync(activity, cancellationToken));
        }

        return Ok(new CustomerCreditActivityListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(CustomerCreditActivityDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CustomerCreditActivityDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var activity = await _activities.GetByIdAsync(id, cancellationToken);
        return activity is null ? NotFound() : Ok(await ToDtoAsync(activity, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(CustomerCreditActivityDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CustomerCreditActivityDto>> Create(CreateCustomerCreditActivityRequest request, CancellationToken cancellationToken = default)
    {
        if (request.Amount <= 0)
        {
            return BadRequest("Amount must be greater than zero.");
        }

        if (!Enum.IsDefined(request.Action))
        {
            return BadRequest("Invalid customer credit action.");
        }

        var customer = await _customers.GetByIdAsync(request.CustomerId, cancellationToken);
        if (customer is null)
        {
            return BadRequest("Customer does not exist.");
        }

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.CustomerCredit, cancellationToken);
        var activity = new CustomerCreditActivity(
            request.CustomerId,
            request.ActivityDate,
            request.Amount,
            request.Action,
            request.InvoiceId,
            request.RefundAccountId,
            request.PaymentMethod,
            allocation.DocumentNo);
        activity.SetSyncIdentity(allocation.DeviceId, allocation.DocumentNo);

        await _activities.AddAsync(activity, cancellationToken);

        var postingResult = await _postingService.PostAsync(activity.Id, cancellationToken);
        if (!postingResult.Succeeded)
        {
            return BadRequest(postingResult.ErrorMessage);
        }

        var savedActivity = await _activities.GetByIdAsync(activity.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = activity.Id }, await ToDtoAsync(savedActivity!, cancellationToken));
    }

    [HttpPost("{id:guid}/post")]
    [ProducesResponseType(typeof(CustomerCreditActivityDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CustomerCreditActivityDto>> Post(Guid id, CancellationToken cancellationToken = default)
    {
        var activity = await _activities.GetByIdAsync(id, cancellationToken);
        if (activity is null)
        {
            return NotFound();
        }

        var postingResult = await _postingService.PostAsync(activity.Id, cancellationToken);
        if (!postingResult.Succeeded)
        {
            return BadRequest(postingResult.ErrorMessage);
        }

        var updatedActivity = await _activities.GetByIdAsync(activity.Id, cancellationToken);
        return Ok(await ToDtoAsync(updatedActivity!, cancellationToken));
    }

    private async Task<CustomerCreditActivityDto> ToDtoAsync(CustomerCreditActivity activity, CancellationToken cancellationToken)
    {
        var customer = await _customers.GetByIdAsync(activity.CustomerId, cancellationToken);
        var invoice = activity.InvoiceId is null ? null : await _invoices.GetByIdAsync(activity.InvoiceId.Value, cancellationToken);
        var refundAccount = activity.RefundAccountId is null ? null : await _accounts.GetByIdAsync(activity.RefundAccountId.Value, cancellationToken);

        return new CustomerCreditActivityDto(
            activity.Id,
            activity.ReferenceNumber,
            activity.CustomerId,
            customer?.DisplayName,
            activity.ActivityDate,
            activity.Amount,
            activity.Action,
            activity.InvoiceId,
            invoice?.InvoiceNumber,
            activity.RefundAccountId,
            refundAccount?.Name,
            activity.PaymentMethod,
            activity.Status,
            activity.PostedTransactionId,
            activity.PostedAt);
    }
}
