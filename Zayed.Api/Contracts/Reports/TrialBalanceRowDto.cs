using Zayed.Core.Accounting;

namespace Zayed.Api.Contracts.Reports;

public sealed record TrialBalanceRowDto(
    Guid AccountId,
    string AccountCode,
    string AccountName,
    AccountType AccountType,
    decimal TotalDebit,
    decimal TotalCredit,
    decimal ClosingDebit,
    decimal ClosingCredit);
