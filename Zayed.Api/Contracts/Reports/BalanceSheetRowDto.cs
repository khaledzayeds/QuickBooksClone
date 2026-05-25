using Zayed.Core.Accounting;

namespace Zayed.Api.Contracts.Reports;

public sealed record BalanceSheetRowDto(
    Guid AccountId,
    string AccountCode,
    string AccountName,
    AccountType AccountType,
    decimal Amount);
