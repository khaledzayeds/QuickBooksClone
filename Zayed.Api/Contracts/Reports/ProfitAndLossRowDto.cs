using Zayed.Core.Accounting;

namespace Zayed.Api.Contracts.Reports;

public sealed record ProfitAndLossRowDto(
    Guid AccountId,
    string AccountCode,
    string AccountName,
    AccountType AccountType,
    decimal Amount);
