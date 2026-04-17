using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Accounting;
using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/transactions")]
public sealed class TransactionsController : ControllerBase
{
    private readonly IAccountingTransactionRepository _transactions;
    private readonly IAccountRepository _accounts;

    public TransactionsController(IAccountingTransactionRepository transactions, IAccountRepository accounts)
    {
        _transactions = transactions;
        _accounts = accounts;
    }

    [HttpGet]
    [ProducesResponseType(typeof(AccountingTransactionListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<AccountingTransactionListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] string? sourceEntityType,
        [FromQuery] Guid? sourceEntityId,
        [FromQuery] bool includeVoided = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        var result = await _transactions.SearchAsync(new AccountingTransactionSearch(search, sourceEntityType, sourceEntityId, includeVoided, page, pageSize), cancellationToken);
        var items = new List<AccountingTransactionDto>();

        foreach (var transaction in result.Items)
        {
            items.Add(await ToDtoAsync(transaction, cancellationToken));
        }

        return Ok(new AccountingTransactionListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(AccountingTransactionDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AccountingTransactionDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var transaction = await _transactions.GetByIdAsync(id, cancellationToken);
        return transaction is null ? NotFound() : Ok(await ToDtoAsync(transaction, cancellationToken));
    }

    private async Task<AccountingTransactionDto> ToDtoAsync(AccountingTransaction transaction, CancellationToken cancellationToken)
    {
        var lines = new List<AccountingTransactionLineDto>();

        foreach (var line in transaction.Lines)
        {
            var account = await _accounts.GetByIdAsync(line.AccountId, cancellationToken);

            lines.Add(new AccountingTransactionLineDto(
                line.Id,
                line.AccountId,
                account?.Code,
                account?.Name,
                line.Description,
                line.Debit,
                line.Credit));
        }

        return new AccountingTransactionDto(
            transaction.Id,
            transaction.TransactionType,
            transaction.TransactionDate,
            transaction.ReferenceNumber,
            transaction.SourceEntityType,
            transaction.SourceEntityId,
            transaction.Status,
            transaction.TotalDebit,
            transaction.TotalCredit,
            lines);
    }
}
