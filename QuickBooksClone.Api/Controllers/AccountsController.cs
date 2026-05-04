using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Contracts.Accounting;
using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/accounts")]
[RequirePermission("Accounting.View")]
public sealed class AccountsController : ControllerBase
{
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public AccountsController(IAccountRepository accounts, IAccountingTransactionRepository transactions)
    {
        _accounts = accounts;
        _transactions = transactions;
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
        var balances = await GetAccountBalancesAsync(cancellationToken);

        return Ok(new AccountListResponse(
            result.Items.Select(account => ToDto(account, balances)).ToList(),
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
        var balances = await GetAccountBalancesAsync(cancellationToken);
        return account is null ? NotFound() : Ok(ToDto(account, balances));
    }

    [HttpPost]
    [RequirePermission("Accounting.Manage")]
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

        var balances = await GetAccountBalancesAsync(cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = account.Id }, ToDto(account, balances));
    }

    [HttpPut("{id:guid}")]
    [RequirePermission("Accounting.Manage")]
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
        var balances = await GetAccountBalancesAsync(cancellationToken);
        return account is null ? NotFound() : Ok(ToDto(account, balances));
    }

    [HttpPatch("{id:guid}/active")]
    [RequirePermission("Accounting.Manage")]
    [ProducesResponseType(typeof(AccountDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AccountDto>> SetActive(Guid id, SetAccountActiveRequest request, CancellationToken cancellationToken = default)
    {
        var updated = await _accounts.SetActiveAsync(id, request.IsActive, cancellationToken);
        if (!updated)
        {
            return NotFound();
        }

        var account = await _accounts.GetByIdAsync(id, cancellationToken);
        if (account is null)
        {
            return NotFound();
        }

        var balances = await GetAccountBalancesAsync(cancellationToken);
        return Ok(ToDto(account, balances));
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

    private async Task<Dictionary<Guid, decimal>> GetAccountBalancesAsync(CancellationToken cancellationToken)
    {
        var result = await _transactions.SearchAsync(new AccountingTransactionSearch(null, IncludeVoided: false, PageSize: 200), cancellationToken);
        var accounts = await _accounts.SearchAsync(new AccountSearch(null, null, true, 1, 200), cancellationToken);
        var accountTypes = accounts.Items.ToDictionary(account => account.Id, account => account.AccountType);
        var balances = new Dictionary<Guid, decimal>();

        foreach (var transaction in result.Items)
        {
            foreach (var line in transaction.Lines)
            {
                accountTypes.TryGetValue(line.AccountId, out var accountType);
                var signedAmount = IsDebitNormal(accountType)
                    ? line.Debit - line.Credit
                    : line.Credit - line.Debit;

                balances[line.AccountId] = balances.GetValueOrDefault(line.AccountId) + signedAmount;
            }
        }

        return balances;
    }

    private static bool IsDebitNormal(AccountType accountType)
    {
        return accountType is AccountType.Bank
            or AccountType.AccountsReceivable
            or AccountType.OtherCurrentAsset
            or AccountType.InventoryAsset
            or AccountType.FixedAsset
            or AccountType.CostOfGoodsSold
            or AccountType.Expense
            or AccountType.OtherExpense;
    }

    private static AccountDto ToDto(Account account, IReadOnlyDictionary<Guid, decimal> balances)
    {
        return new AccountDto(
            account.Id,
            account.Code,
            account.Name,
            account.AccountType,
            account.Description,
            account.ParentId,
            account.IsActive,
            balances.GetValueOrDefault(account.Id));
    }
}
