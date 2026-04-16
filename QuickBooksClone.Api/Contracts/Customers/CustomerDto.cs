namespace QuickBooksClone.Api.Contracts.Customers;

public sealed record CustomerDto(
    Guid Id,
    string DisplayName,
    string? CompanyName,
    string? Email,
    string? Phone,
    string Currency,
    decimal Balance,
    bool IsActive);
