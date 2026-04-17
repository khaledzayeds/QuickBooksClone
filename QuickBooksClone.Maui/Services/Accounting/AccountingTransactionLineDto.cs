namespace QuickBooksClone.Maui.Services.Accounting;

public sealed record AccountingTransactionLineDto(
    Guid Id,
    Guid AccountId,
    string? AccountCode,
    string? AccountName,
    string Description,
    decimal Debit,
    decimal Credit);
