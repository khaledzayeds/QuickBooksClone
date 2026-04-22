using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record TrialBalanceRowDto(
    Guid AccountId,
    string AccountCode,
    string AccountName,
    AccountType AccountType,
    decimal TotalDebit,
    decimal TotalCredit,
    decimal ClosingDebit,
    decimal ClosingCredit);
