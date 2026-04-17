namespace QuickBooksClone.Maui.Services.Accounting;

public sealed record AccountDto(
    Guid Id,
    string Code,
    string Name,
    AccountType AccountType,
    string? Description,
    Guid? ParentId,
    bool IsActive,
    decimal Balance);
