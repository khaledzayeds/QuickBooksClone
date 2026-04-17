namespace QuickBooksClone.Core.Accounting;

public interface IAccountingTransactionRepository
{
    Task<AccountingTransactionListResult> SearchAsync(AccountingTransactionSearch search, CancellationToken cancellationToken = default);
    Task<AccountingTransaction?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<AccountingTransaction?> GetBySourceAsync(string sourceEntityType, Guid sourceEntityId, CancellationToken cancellationToken = default);
    Task<AccountingTransaction> AddAsync(AccountingTransaction transaction, CancellationToken cancellationToken = default);
}
