using System.Collections.Concurrent;
using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Infrastructure.Accounting;

public sealed class InMemoryAccountRepository : IAccountRepository
{
    private readonly ConcurrentDictionary<Guid, Account> _accounts = new();

    public InMemoryAccountRepository()
    {
        Seed(new Account("1000", "Cash on Hand", AccountType.Bank));
        Seed(new Account("1100", "Accounts Receivable", AccountType.AccountsReceivable));
        Seed(new Account("1200", "Inventory Asset", AccountType.InventoryAsset));
        Seed(new Account("2000", "Accounts Payable", AccountType.AccountsPayable));
        Seed(new Account("3000", "Owner Equity", AccountType.Equity));
        Seed(new Account("4000", "Sales Income", AccountType.Income));
        Seed(new Account("5000", "Cost of Goods Sold", AccountType.CostOfGoodsSold));
        Seed(new Account("6000", "General Expenses", AccountType.Expense));
    }

    public Task<AccountListResult> SearchAsync(AccountSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 200);
        var query = _accounts.Values.AsEnumerable();

        if (!search.IncludeInactive)
        {
            query = query.Where(account => account.IsActive);
        }

        if (search.AccountType is not null)
        {
            query = query.Where(account => account.AccountType == search.AccountType);
        }

        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = search.Search.Trim();
            query = query.Where(account =>
                account.Code.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                account.Name.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                account.AccountType.ToString().Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = query
            .OrderBy(account => account.Code)
            .ThenBy(account => account.Name)
            .ToList();

        var items = ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Task.FromResult(new AccountListResult(items, ordered.Count, page, pageSize));
    }

    public Task<Account?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _accounts.TryGetValue(id, out var account);
        return Task.FromResult(account);
    }

    public Task<bool> CodeExistsAsync(string code, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Exists(account => Same(account.Code, code), excludingId));
    }

    public Task<bool> NameExistsAsync(string name, Guid? excludingId = null, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Exists(account => Same(account.Name, name), excludingId));
    }

    public Task<Account> AddAsync(Account account, CancellationToken cancellationToken = default)
    {
        _accounts[account.Id] = account;
        return Task.FromResult(account);
    }

    public Task<Account?> UpdateAsync(Guid id, string code, string name, AccountType accountType, string? description, Guid? parentId, CancellationToken cancellationToken = default)
    {
        if (!_accounts.TryGetValue(id, out var account))
        {
            return Task.FromResult<Account?>(null);
        }

        account.Update(code, name, accountType, description, parentId);
        return Task.FromResult<Account?>(account);
    }

    public Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default)
    {
        if (!_accounts.TryGetValue(id, out var account))
        {
            return Task.FromResult(false);
        }

        account.SetActive(isActive);
        return Task.FromResult(true);
    }

    private void Seed(Account account)
    {
        _accounts[account.Id] = account;
    }

    private bool Exists(Func<Account, bool> predicate, Guid? excludingId)
    {
        return _accounts.Values.Any(account => account.Id != excludingId && predicate(account));
    }

    private static bool Same(string left, string right)
    {
        return string.Equals(left.Trim(), right.Trim(), StringComparison.OrdinalIgnoreCase);
    }
}
