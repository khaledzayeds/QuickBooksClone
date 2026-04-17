namespace QuickBooksClone.Core.Accounting;

public interface IAccountRepository
{
    Task<AccountListResult> SearchAsync(AccountSearch search, CancellationToken cancellationToken = default);
    Task<Account?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> CodeExistsAsync(string code, Guid? excludingId = null, CancellationToken cancellationToken = default);
    Task<bool> NameExistsAsync(string name, Guid? excludingId = null, CancellationToken cancellationToken = default);
    Task<Account> AddAsync(Account account, CancellationToken cancellationToken = default);
    Task<Account?> UpdateAsync(Guid id, string code, string name, AccountType accountType, string? description, Guid? parentId, CancellationToken cancellationToken = default);
    Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default);
}
