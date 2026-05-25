using Zayed.Core.Accounting;

namespace Zayed.Api.Contracts.Accounting;

public sealed record AccountingTransactionDto(
    Guid Id,
    string TransactionType,
    DateOnly TransactionDate,
    string ReferenceNumber,
    string? SourceEntityType,
    Guid? SourceEntityId,
    AccountingTransactionStatus Status,
    decimal TotalDebit,
    decimal TotalCredit,
    IReadOnlyList<AccountingTransactionLineDto> Lines);
