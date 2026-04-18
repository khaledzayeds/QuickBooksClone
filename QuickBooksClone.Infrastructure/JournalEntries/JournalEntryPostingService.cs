using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.JournalEntries;

namespace QuickBooksClone.Infrastructure.JournalEntries;

public sealed class JournalEntryPostingService : IJournalEntryPostingService
{
    private const string JournalEntrySourceEntityType = "JournalEntry";
    private const string JournalEntryReversalSourceEntityType = "JournalEntryReversal";

    private readonly IJournalEntryRepository _journalEntries;
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public JournalEntryPostingService(
        IJournalEntryRepository journalEntries,
        IAccountRepository accounts,
        IAccountingTransactionRepository transactions)
    {
        _journalEntries = journalEntries;
        _accounts = accounts;
        _transactions = transactions;
    }

    public async Task<JournalEntryPostingResult> PostAsync(Guid journalEntryId, CancellationToken cancellationToken = default)
    {
        var journalEntry = await _journalEntries.GetByIdAsync(journalEntryId, cancellationToken);
        if (journalEntry is null)
        {
            return JournalEntryPostingResult.Failure("Journal entry does not exist.");
        }

        if (journalEntry.Status == JournalEntryStatus.Void)
        {
            return JournalEntryPostingResult.Failure("Cannot post a void journal entry.");
        }

        if (journalEntry.PostedTransactionId is not null)
        {
            return JournalEntryPostingResult.Success(journalEntry.PostedTransactionId.Value);
        }

        var existingTransaction = await _transactions.GetBySourceAsync(JournalEntrySourceEntityType, journalEntry.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            await _journalEntries.MarkPostedAsync(journalEntry.Id, existingTransaction.Id, cancellationToken);
            return JournalEntryPostingResult.Success(existingTransaction.Id);
        }

        var validation = await ValidateLinesAsync(journalEntry, cancellationToken);
        if (validation is not null)
        {
            return JournalEntryPostingResult.Failure(validation);
        }

        var transaction = BuildAccountingTransaction(journalEntry);
        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);
        await _journalEntries.MarkPostedAsync(journalEntry.Id, savedTransaction.Id, cancellationToken);

        return JournalEntryPostingResult.Success(savedTransaction.Id);
    }

    public async Task<JournalEntryPostingResult> VoidAsync(Guid journalEntryId, CancellationToken cancellationToken = default)
    {
        var journalEntry = await _journalEntries.GetByIdAsync(journalEntryId, cancellationToken);
        if (journalEntry is null)
        {
            return JournalEntryPostingResult.Failure("Journal entry does not exist.");
        }

        if (journalEntry.Status == JournalEntryStatus.Void)
        {
            return JournalEntryPostingResult.Success(journalEntry.ReversalTransactionId);
        }

        if (journalEntry.PostedTransactionId is null)
        {
            await _journalEntries.VoidAsync(journalEntry.Id, null, cancellationToken);
            return JournalEntryPostingResult.Success();
        }

        var existingReversal = await _transactions.GetBySourceAsync(JournalEntryReversalSourceEntityType, journalEntry.Id, cancellationToken);
        if (existingReversal is not null)
        {
            await _journalEntries.VoidAsync(journalEntry.Id, existingReversal.Id, cancellationToken);
            return JournalEntryPostingResult.Success(existingReversal.Id);
        }

        var originalTransaction = await _transactions.GetByIdAsync(journalEntry.PostedTransactionId.Value, cancellationToken);
        if (originalTransaction is null)
        {
            return JournalEntryPostingResult.Failure("Posted journal entry transaction is missing.");
        }

        var reversalTransaction = BuildReversalTransaction(journalEntry, originalTransaction);
        var savedReversal = await _transactions.AddAsync(reversalTransaction, cancellationToken);
        await _journalEntries.VoidAsync(journalEntry.Id, savedReversal.Id, cancellationToken);

        return JournalEntryPostingResult.Success(savedReversal.Id);
    }

    private async Task<string?> ValidateLinesAsync(JournalEntry journalEntry, CancellationToken cancellationToken)
    {
        foreach (var line in journalEntry.Lines)
        {
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

    private static AccountingTransaction BuildAccountingTransaction(JournalEntry journalEntry)
    {
        var transaction = new AccountingTransaction(
            "JournalEntry",
            journalEntry.EntryDate,
            journalEntry.EntryNumber,
            JournalEntrySourceEntityType,
            journalEntry.Id);

        foreach (var line in journalEntry.Lines)
        {
            transaction.AddLine(new AccountingTransactionLine(
                line.AccountId,
                line.Description,
                line.Debit,
                line.Credit));
        }

        return transaction;
    }

    private static AccountingTransaction BuildReversalTransaction(JournalEntry journalEntry, AccountingTransaction originalTransaction)
    {
        var transaction = new AccountingTransaction(
            "JournalEntryReversal",
            DateOnly.FromDateTime(DateTime.UtcNow),
            $"{journalEntry.EntryNumber}-VOID",
            JournalEntryReversalSourceEntityType,
            journalEntry.Id);

        foreach (var line in originalTransaction.Lines)
        {
            transaction.AddLine(new AccountingTransactionLine(
                line.AccountId,
                $"Reversal - {line.Description}",
                line.Credit,
                line.Debit));
        }

        return transaction;
    }
}
