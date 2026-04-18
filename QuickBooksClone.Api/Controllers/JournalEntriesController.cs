using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.JournalEntries;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.JournalEntries;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/journal-entries")]
public sealed class JournalEntriesController : ControllerBase
{
    private readonly IJournalEntryRepository _journalEntries;
    private readonly IJournalEntryPostingService _postingService;
    private readonly IAccountRepository _accounts;

    public JournalEntriesController(
        IJournalEntryRepository journalEntries,
        IJournalEntryPostingService postingService,
        IAccountRepository accounts)
    {
        _journalEntries = journalEntries;
        _postingService = postingService;
        _accounts = accounts;
    }

    [HttpGet]
    [ProducesResponseType(typeof(JournalEntryListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<JournalEntryListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] bool includeVoid = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _journalEntries.SearchAsync(new JournalEntrySearch(search, includeVoid, page, pageSize), cancellationToken);
        var items = new List<JournalEntryDto>();

        foreach (var entry in result.Items)
        {
            items.Add(await ToDtoAsync(entry, cancellationToken));
        }

        return Ok(new JournalEntryListResponse(items, result.TotalCount, result.Page, result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(JournalEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<JournalEntryDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var entry = await _journalEntries.GetByIdAsync(id, cancellationToken);
        return entry is null ? NotFound() : Ok(await ToDtoAsync(entry, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(JournalEntryDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<JournalEntryDto>> Create(CreateJournalEntryRequest request, CancellationToken cancellationToken = default)
    {
        var validation = await ValidateRequestAsync(request, cancellationToken);
        if (validation is not null)
        {
            return BadRequest(validation);
        }

        var lines = request.Lines
            .Select(line => new JournalEntryLine(line.AccountId, line.Description ?? request.Memo ?? "Manual journal entry", line.Debit, line.Credit))
            .ToList();

        var entry = new JournalEntry(request.EntryDate, request.Memo ?? "Manual journal entry", lines);
        await _journalEntries.AddAsync(entry, cancellationToken);

        if (request.SaveMode == JournalEntrySaveMode.SaveAndPost)
        {
            var postingResult = await _postingService.PostAsync(entry.Id, cancellationToken);
            if (!postingResult.Succeeded)
            {
                return BadRequest(postingResult.ErrorMessage);
            }
        }

        var savedEntry = await _journalEntries.GetByIdAsync(entry.Id, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = entry.Id }, await ToDtoAsync(savedEntry!, cancellationToken));
    }

    [HttpPost("{id:guid}/post")]
    [ProducesResponseType(typeof(JournalEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<JournalEntryDto>> Post(Guid id, CancellationToken cancellationToken = default)
    {
        var entry = await _journalEntries.GetByIdAsync(id, cancellationToken);
        if (entry is null)
        {
            return NotFound();
        }

        var result = await _postingService.PostAsync(id, cancellationToken);
        if (!result.Succeeded)
        {
            return BadRequest(result.ErrorMessage);
        }

        var savedEntry = await _journalEntries.GetByIdAsync(id, cancellationToken);
        return Ok(await ToDtoAsync(savedEntry!, cancellationToken));
    }

    [HttpPatch("{id:guid}/void")]
    [ProducesResponseType(typeof(JournalEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<JournalEntryDto>> Void(Guid id, CancellationToken cancellationToken = default)
    {
        var entry = await _journalEntries.GetByIdAsync(id, cancellationToken);
        if (entry is null)
        {
            return NotFound();
        }

        var result = await _postingService.VoidAsync(id, cancellationToken);
        if (!result.Succeeded)
        {
            return BadRequest(result.ErrorMessage);
        }

        var savedEntry = await _journalEntries.GetByIdAsync(id, cancellationToken);
        return Ok(await ToDtoAsync(savedEntry!, cancellationToken));
    }

    private async Task<string?> ValidateRequestAsync(CreateJournalEntryRequest request, CancellationToken cancellationToken)
    {
        if (request.Lines.Count < 2)
        {
            return "Journal entry must have at least two lines.";
        }

        if (request.SaveMode is not JournalEntrySaveMode.Draft and not JournalEntrySaveMode.SaveAndPost)
        {
            return "Invalid journal entry save mode.";
        }

        var totalDebit = request.Lines.Sum(line => line.Debit);
        var totalCredit = request.Lines.Sum(line => line.Credit);
        if (totalDebit <= 0 || totalCredit <= 0 || totalDebit != totalCredit)
        {
            return "Journal entry debits and credits must be balanced.";
        }

        foreach (var line in request.Lines)
        {
            if (line.AccountId == Guid.Empty)
            {
                return "Every journal entry line must have an account.";
            }

            if (line.Debit < 0 || line.Credit < 0)
            {
                return "Debit and credit cannot be negative.";
            }

            if (line.Debit == 0 && line.Credit == 0)
            {
                return "Every journal entry line must have a debit or credit amount.";
            }

            if (line.Debit > 0 && line.Credit > 0)
            {
                return "A journal entry line cannot have both debit and credit.";
            }

            var account = await _accounts.GetByIdAsync(line.AccountId, cancellationToken);
            if (account is null)
            {
                return $"Account does not exist: {line.AccountId}";
            }

            if (!account.IsActive)
            {
                return $"Account '{account.Name}' is inactive.";
            }

            if (account.AccountType is AccountType.AccountsReceivable or AccountType.AccountsPayable)
            {
                return "Manual journal entries cannot post directly to Accounts Receivable or Accounts Payable yet. Use customer/vendor documents so subledger balances stay in sync.";
            }
        }

        return null;
    }

    private async Task<JournalEntryDto> ToDtoAsync(JournalEntry entry, CancellationToken cancellationToken)
    {
        var lines = new List<JournalEntryLineDto>();
        foreach (var line in entry.Lines)
        {
            var account = await _accounts.GetByIdAsync(line.AccountId, cancellationToken);
            lines.Add(new JournalEntryLineDto(
                line.Id,
                line.AccountId,
                account?.Code,
                account?.Name,
                line.Description,
                line.Debit,
                line.Credit));
        }

        return new JournalEntryDto(
            entry.Id,
            entry.EntryNumber,
            entry.EntryDate,
            entry.Memo,
            entry.Status,
            entry.TotalDebit,
            entry.TotalCredit,
            entry.PostedTransactionId,
            entry.ReversalTransactionId,
            entry.PostedAt,
            entry.VoidedAt,
            lines);
    }
}
