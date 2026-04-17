using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Accounting;
using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/accounts")]
public sealed class AccountsController : ControllerBase
{
    private readonly IAccountRepository _accounts;

    public AccountsController(IAccountRepository accounts)
    {
        _accounts = accounts;
    }

    [HttpGet]
    [ProducesResponseType(typeof(AccountListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<AccountListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] AccountType? accountType,
        [FromQuery] bool includeInactive = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 100,
        CancellationToken cancellationToken = default)
    {
        var result = await _accounts.SearchAsync(new AccountSearch(search, accountType, includeInactive, page, pageSize), cancellationToken);

        return Ok(new AccountListResponse(
            result.Items.Select(ToDto).ToList(),
            result.TotalCount,
            result.Page,
            result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(AccountDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AccountDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var account = await _accounts.GetByIdAsync(id, cancellationToken);
        return account is null ? NotFound() : Ok(ToDto(account));
    }

    [HttpPost]
    [ProducesResponseType(typeof(AccountDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<AccountDto>> Create(CreateAccountRequest request, CancellationToken cancellationToken = default)
    {
        var duplicateValidation = await ValidateUniqueAccountAsync(request.Code, request.Name, null, cancellationToken);
        if (duplicateValidation is not null)
        {
            return Conflict(duplicateValidation);
        }

        if (request.ParentId is not null && await _accounts.GetByIdAsync(request.ParentId.Value, cancellationToken) is null)
        {
            return BadRequest("Parent account does not exist.");
        }

        var account = new Account(request.Code, request.Name, request.AccountType, request.Description, request.ParentId);
        await _accounts.AddAsync(account, cancellationToken);

        return CreatedAtAction(nameof(Get), new { id = account.Id }, ToDto(account));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(AccountDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<AccountDto>> Update(Guid id, UpdateAccountRequest request, CancellationToken cancellationToken = default)
    {
        var duplicateValidation = await ValidateUniqueAccountAsync(request.Code, request.Name, id, cancellationToken);
        if (duplicateValidation is not null)
        {
            return Conflict(duplicateValidation);
        }

        if (request.ParentId == id)
        {
            return BadRequest("Account cannot be its own parent.");
        }

        if (request.ParentId is not null && await _accounts.GetByIdAsync(request.ParentId.Value, cancellationToken) is null)
        {
            return BadRequest("Parent account does not exist.");
        }

        var account = await _accounts.UpdateAsync(id, request.Code, request.Name, request.AccountType, request.Description, request.ParentId, cancellationToken);
        return account is null ? NotFound() : Ok(ToDto(account));
    }

    [HttpPatch("{id:guid}/active")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetActive(Guid id, SetAccountActiveRequest request, CancellationToken cancellationToken = default)
    {
        var updated = await _accounts.SetActiveAsync(id, request.IsActive, cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    private async Task<string?> ValidateUniqueAccountAsync(
        string code,
        string name,
        Guid? excludingId,
        CancellationToken cancellationToken)
    {
        if (await _accounts.CodeExistsAsync(code, excludingId, cancellationToken))
        {
            return "Account code already exists.";
        }

        if (await _accounts.NameExistsAsync(name, excludingId, cancellationToken))
        {
            return "Account name already exists.";
        }

        return null;
    }

    private static AccountDto ToDto(Account account)
    {
        return new AccountDto(
            account.Id,
            account.Code,
            account.Name,
            account.AccountType,
            account.Description,
            account.ParentId,
            account.IsActive);
    }
}
