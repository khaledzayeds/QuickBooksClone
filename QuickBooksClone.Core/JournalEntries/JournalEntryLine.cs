namespace QuickBooksClone.Core.JournalEntries;

public sealed class JournalEntryLine
{
    private JournalEntryLine()
    {
        Description = string.Empty;
    }

    public JournalEntryLine(Guid accountId, string description, decimal debit, decimal credit)
    {
        if (accountId == Guid.Empty)
        {
            throw new ArgumentException("Account is required.", nameof(accountId));
        }

        if (debit < 0 || credit < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(debit), "Debit and credit cannot be negative.");
        }

        if (debit == 0 && credit == 0)
        {
            throw new ArgumentException("Line must have a debit or credit amount.");
        }

        if (debit > 0 && credit > 0)
        {
            throw new ArgumentException("Line cannot have both debit and credit.");
        }

        AccountId = accountId;
        Description = string.IsNullOrWhiteSpace(description) ? "Journal entry line" : description.Trim();
        Debit = debit;
        Credit = credit;
    }

    public Guid Id { get; } = Guid.NewGuid();
    public Guid AccountId { get; }
    public string Description { get; }
    public decimal Debit { get; }
    public decimal Credit { get; }
}
