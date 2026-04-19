using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.JournalEntries;

public sealed class JournalEntry : EntityBase, ITenantEntity
{
    private readonly List<JournalEntryLine> _lines = [];

    private JournalEntry()
    {
        CompanyId = Guid.Empty;
        EntryNumber = string.Empty;
        Memo = string.Empty;
    }

    public JournalEntry(
        DateOnly entryDate,
        string memo,
        IEnumerable<JournalEntryLine> lines,
        string? entryNumber = null,
        Guid? companyId = null)
    {
        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        EntryDate = entryDate;
        Memo = string.IsNullOrWhiteSpace(memo) ? "Manual journal entry" : memo.Trim();
        EntryNumber = string.IsNullOrWhiteSpace(entryNumber) ? $"JE-{DateTimeOffset.UtcNow:yyyyMMddHHmmssfff}" : entryNumber.Trim();
        Status = JournalEntryStatus.Draft;

        foreach (var line in lines)
        {
            _lines.Add(line);
        }

        ValidateBalanced();
    }

    public Guid CompanyId { get; }
    public DateOnly EntryDate { get; }
    public string EntryNumber { get; }
    public string Memo { get; }
    public JournalEntryStatus Status { get; private set; }
    public Guid? PostedTransactionId { get; private set; }
    public Guid? ReversalTransactionId { get; private set; }
    public DateTimeOffset? PostedAt { get; private set; }
    public DateTimeOffset? VoidedAt { get; private set; }
    public IReadOnlyList<JournalEntryLine> Lines => _lines;
    public decimal TotalDebit => _lines.Sum(line => line.Debit);
    public decimal TotalCredit => _lines.Sum(line => line.Credit);

    public void MarkPosted(Guid transactionId)
    {
        if (Status == JournalEntryStatus.Void)
        {
            throw new InvalidOperationException("Cannot post a void journal entry.");
        }

        if (PostedTransactionId is not null)
        {
            throw new InvalidOperationException("Journal entry is already posted.");
        }

        PostedTransactionId = transactionId;
        PostedAt = DateTimeOffset.UtcNow;
        Status = JournalEntryStatus.Posted;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Void(Guid? reversalTransactionId)
    {
        if (Status == JournalEntryStatus.Void)
        {
            return;
        }

        ReversalTransactionId = reversalTransactionId;
        VoidedAt = DateTimeOffset.UtcNow;
        Status = JournalEntryStatus.Void;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    private void ValidateBalanced()
    {
        if (_lines.Count < 2)
        {
            throw new InvalidOperationException("Journal entry must have at least two lines.");
        }

        if (TotalDebit <= 0 || TotalCredit <= 0)
        {
            throw new InvalidOperationException("Journal entry must include debit and credit amounts.");
        }

        if (TotalDebit != TotalCredit)
        {
            throw new InvalidOperationException("Journal entry is not balanced.");
        }
    }
}
