namespace QuickBooksClone.Core.Accounting;

public sealed record DefaultAccountDefinition(
    string Code,
    string Name,
    AccountType AccountType,
    string Description);

public sealed record DefaultAccountsSeedResult(
    int CreatedCount,
    int SkippedCount,
    IReadOnlyList<string> CreatedCodes,
    IReadOnlyList<string> SkippedCodes);

public interface IDefaultAccountsSeeder
{
    Task<DefaultAccountsSeedResult> SeedAsync(CancellationToken cancellationToken = default);
}
