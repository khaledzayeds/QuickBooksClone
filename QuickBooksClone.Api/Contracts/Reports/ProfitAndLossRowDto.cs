using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record ProfitAndLossRowDto(
    Guid AccountId,
    string AccountCode,
    string AccountName,
    AccountType AccountType,
    decimal Amount);
