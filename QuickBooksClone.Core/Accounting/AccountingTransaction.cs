using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Accounting;

public sealed class AccountingTransaction : EntityBase, ITenantEntity
{
    private readonly List<AccountingTransactionLine> _lines = [];

    private AccountingTransaction()
    {
        CompanyId = Guid.Empty;
        TransactionType = string.Empty;
        ReferenceNumber = string.Empty;
    }

    public AccountingTransaction(
        string transactionType,
        DateOnly transactionDate,
        string referenceNumber,
        string? sourceEntityType = null,
        Guid? sourceEntityId = null,
        Guid? companyId = null)
    {
        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        TransactionType = string.IsNullOrWhiteSpace(transactionType) ? "JournalEntry" : transactionType.Trim();
        TransactionDate = transactionDate;
        ReferenceNumber = string.IsNullOrWhiteSpace(referenceNumber) ? $"TXN-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}" : referenceNumber.Trim();
        SourceEntityType = string.IsNullOrWhiteSpace(sourceEntityType) ? null : sourceEntityType.Trim();
        SourceEntityId = sourceEntityId;
        Status = AccountingTransactionStatus.Posted;
    }

    public Guid CompanyId { get; }
    public string TransactionType { get; }
    public DateOnly TransactionDate { get; }
    public string ReferenceNumber { get; }
    public string? SourceEntityType { get; }
    public Guid? SourceEntityId { get; }
    public AccountingTransactionStatus Status { get; private set; }
    public IReadOnlyList<AccountingTransactionLine> Lines => _lines;
    public decimal TotalDebit => _lines.Sum(line => line.Debit);
    public decimal TotalCredit => _lines.Sum(line => line.Credit);

    public void AddLine(AccountingTransactionLine line)
    {
        if (Status == AccountingTransactionStatus.Voided)
        {
            throw new InvalidOperationException("Cannot change a void transaction.");
        }

        _lines.Add(line);
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ValidateBalanced()
    {
        if (_lines.Count < 2)
        {
            throw new InvalidOperationException("Transaction must have at least two lines.");
        }

        if (TotalDebit != TotalCredit)
        {
            throw new InvalidOperationException("Transaction is not balanced.");
        }
    }

    public void Void()
    {
        Status = AccountingTransactionStatus.Voided;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
