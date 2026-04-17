namespace QuickBooksClone.Core.Accounting;

public sealed record AccountingTransactionListResult(
    IReadOnlyList<AccountingTransaction> Items,
    int TotalCount,
    int Page,
    int PageSize);
