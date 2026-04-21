using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.VendorCredits;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.VendorCredits;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/vendor-credits")]
public sealed class VendorCreditsController : ControllerBase
{
    private readonly IVendorCreditActivityRepository _activities;
    private readonly IVendorCreditPostingService _postingService;
    private readonly IVendorRepository _vendors;
    private readonly IPurchaseBillRepository _bills;
    private readonly IAccountRepository _accounts;
    private readonly IDocumentNumberService _documentNumbers;

    public VendorCreditsController(IVendorCreditActivityRepository activities, IVendorCreditPostingService postingService, IVendorRepository vendors, IPurchaseBillRepository bills, IAccountRepository accounts, IDocumentNumberService documentNumbers)
    {
        _activities = activities;
        _postingService = postingService;
        _vendors = vendors;
        _bills = bills;
        _accounts = accounts;
        _documentNumbers = documentNumbers;
    }

    [HttpGet]
    [ProducesResponseType(typeof(VendorCreditActivityListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<VendorCreditActivityListResponse>> Search([FromQuery] string? search, [FromQuery] Guid? vendorId, [FromQuery] VendorCreditAction? action, [FromQuery] bool includeVoid = false, [FromQuery] int page = 1, [FromQuery] int pageSize = 25, CancellationToken cancellationToken = default)
    {
        var result = await _activities.SearchAsync(new VendorCreditActivitySearch(search, vendorId, action, includeVoid, page, pageSize), cancellationToken);
        var items = new List<VendorCreditActivityDto>();
        foreach (var activity in result.Items)
        {
            items.Add(await ToDtoAsync(activity, cancellationToken));
        }

        return Ok(new VendorCreditActivityListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(VendorCreditActivityDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<VendorCreditActivityDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var activity = await _activities.GetByIdAsync(id, cancellationToken);
        return activity is null ? NotFound() : Ok(await ToDtoAsync(activity, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(VendorCreditActivityDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<VendorCreditActivityDto>> Create(CreateVendorCreditActivityRequest request, CancellationToken cancellationToken = default)
    {
        if (request.Amount <= 0)
        {
            return BadRequest("Amount must be greater than zero.");
        }

        if (!Enum.IsDefined(request.Action))
        {
            return BadRequest("Invalid vendor credit action.");
        }

        var vendor = await _vendors.GetByIdAsync(request.VendorId, cancellationToken);
        if (vendor is null)
        {
            return BadRequest("Vendor does not exist.");
        }

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.VendorCredit, cancellationToken);
        var activity = new VendorCreditActivity(request.VendorId, request.ActivityDate, request.Amount, request.Action, request.PurchaseBillId, request.DepositAccountId, request.PaymentMethod, allocation.DocumentNo);
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

    private async Task<VendorCreditActivityDto> ToDtoAsync(VendorCreditActivity activity, CancellationToken cancellationToken)
    {
        var vendor = await _vendors.GetByIdAsync(activity.VendorId, cancellationToken);
        var bill = activity.PurchaseBillId is null ? null : await _bills.GetByIdAsync(activity.PurchaseBillId.Value, cancellationToken);
        var depositAccount = activity.DepositAccountId is null ? null : await _accounts.GetByIdAsync(activity.DepositAccountId.Value, cancellationToken);
        return new VendorCreditActivityDto(activity.Id, activity.ReferenceNumber, activity.VendorId, vendor?.DisplayName, activity.ActivityDate, activity.Amount, activity.Action, activity.PurchaseBillId, bill?.BillNumber, activity.DepositAccountId, depositAccount?.Name, activity.PaymentMethod, activity.Status, activity.PostedTransactionId, activity.PostedAt);
    }
}
