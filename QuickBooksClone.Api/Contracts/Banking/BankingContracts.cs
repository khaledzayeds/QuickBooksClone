using QuickBooksClone.Core.Accounting;

namespace QuickBooksClone.Api.Contracts.Banking;

public sealed record BankAccountDto(
    Guid Id,
    string Code,
    string Name,
    AccountType AccountType,
    decimal Balance,
    bool IsActive);

public sealed record BankRegisterLineDto(
    Guid TransactionId,
    DateOnly TransactionDate,
    string TransactionType,
    string ReferenceNumber,
    string Description,
    decimal Debit,
    decimal Credit,
    decimal Amount,
    decimal RunningBalance,
    string? SourceEntityType,
    Guid? SourceEntityId);

public sealed record BankRegisterResponse(
    Guid AccountId,
    string AccountName,
    decimal OpeningBalance,
    decimal EndingBalance,
    IReadOnlyList<BankRegisterLineDto> Items);

public sealed record CreateBankTransferRequest(
    Guid FromAccountId,
    Guid ToAccountId,
    DateOnly TransferDate,
    decimal Amount,
    string? Memo);
