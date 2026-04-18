namespace QuickBooksClone.Api.Contracts.Vendors;

public sealed record VendorDto(
    Guid Id,
    string DisplayName,
    string? CompanyName,
    string? Email,
    string? Phone,
    string Currency,
    decimal Balance,
    decimal CreditBalance,
    bool IsActive);
