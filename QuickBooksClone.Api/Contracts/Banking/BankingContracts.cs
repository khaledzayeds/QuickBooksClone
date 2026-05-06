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

public sealed record CreateBankDepositRequest(
    Guid DepositAccountId,
    Guid OffsetAccountId,
    DateOnly DepositDate,
    decimal Amount,
    string? ReceivedFrom,
    string? Memo);

public sealed record CreateBankCheckRequest(
    Guid BankAccountId,
    Guid ExpenseAccountId,
    DateOnly CheckDate,
    decimal Amount,
    string? Payee,
    string? Memo);

public sealed record BankReconcilePreviewRequest(
    Guid AccountId,
    DateOnly StatementDate,
    decimal StatementEndingBalance);

public sealed record BankReconcilePreviewResponse(
    Guid AccountId,
    string AccountName,
    DateOnly StatementDate,
    decimal BookBalance,
    decimal StatementEndingBalance,
    decimal Difference,
    bool IsBalanced,
    IReadOnlyList<BankRegisterLineDto> RegisterLines);
