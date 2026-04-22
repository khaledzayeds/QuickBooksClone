using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record BalanceSheetRowDto(
    Guid AccountId,
    string AccountCode,
    string AccountName,
    AccountType AccountType,
    decimal Amount);
