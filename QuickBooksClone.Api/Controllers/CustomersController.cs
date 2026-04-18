using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Customers;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.OpeningBalances;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/customers")]
public sealed class CustomersController : ControllerBase
{
    private readonly ICustomerRepository _customers;
    private readonly IOpeningBalancePostingService _openingBalances;

    public CustomersController(ICustomerRepository customers, IOpeningBalancePostingService openingBalances)
    {
        _customers = customers;
        _openingBalances = openingBalances;
    }

    [HttpGet]
    [ProducesResponseType(typeof(CustomerListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<CustomerListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] bool includeInactive = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _customers.SearchAsync(new CustomerSearch(search, includeInactive, page, pageSize), cancellationToken);

        return Ok(new CustomerListResponse(
            result.Items.Select(ToDto).ToList(),
            result.TotalCount,
            result.Page,
            result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CustomerDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var customer = await _customers.GetByIdAsync(id, cancellationToken);
        return customer is null ? NotFound() : Ok(ToDto(customer));
    }

    [HttpPost]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<CustomerDto>> Create(CreateCustomerRequest request, CancellationToken cancellationToken = default)
    {
        var duplicateValidation = await ValidateUniqueCustomerAsync(request.DisplayName, request.Email, null, cancellationToken);
        if (duplicateValidation is not null)
        {
            return Conflict(duplicateValidation);
        }

        var customer = new Customer(
            request.DisplayName,
            request.CompanyName,
            request.Email,
            request.Phone,
            request.Currency ?? "EGP",
            request.OpeningBalance);

        await _customers.AddAsync(customer, cancellationToken);
        var openingBalanceResult = await _openingBalances.PostCustomerOpeningBalanceAsync(customer, cancellationToken);
        if (!openingBalanceResult.Succeeded)
        {
            return BadRequest(openingBalanceResult.ErrorMessage);
        }

        return CreatedAtAction(nameof(Get), new { id = customer.Id }, ToDto(customer));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<CustomerDto>> Update(Guid id, UpdateCustomerRequest request, CancellationToken cancellationToken = default)
    {
        var duplicateValidation = await ValidateUniqueCustomerAsync(request.DisplayName, request.Email, id, cancellationToken);
        if (duplicateValidation is not null)
        {
            return Conflict(duplicateValidation);
        }

        var customer = await _customers.UpdateAsync(
            id,
            request.DisplayName,
            request.CompanyName,
            request.Email,
            request.Phone,
            request.Currency ?? "EGP",
            cancellationToken);

        return customer is null ? NotFound() : Ok(ToDto(customer));
    }

    [HttpPatch("{id:guid}/active")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetActive(Guid id, SetCustomerActiveRequest request, CancellationToken cancellationToken = default)
    {
        var updated = await _customers.SetActiveAsync(id, request.IsActive, cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    private async Task<string?> ValidateUniqueCustomerAsync(
        string displayName,
        string? email,
        Guid? excludingId,
        CancellationToken cancellationToken)
    {
        if (await _customers.DisplayNameExistsAsync(displayName, excludingId, cancellationToken))
        {
            return "Customer display name already exists.";
        }

        if (!string.IsNullOrWhiteSpace(email) && await _customers.EmailExistsAsync(email, excludingId, cancellationToken))
        {
            return "Customer email already exists.";
        }

        return null;
    }

    private static CustomerDto ToDto(Customer customer)
    {
        return new CustomerDto(
            customer.Id,
            customer.DisplayName,
            customer.CompanyName,
            customer.Email,
            customer.Phone,
            customer.Currency,
            customer.Balance,
            customer.IsActive);
    }
}
