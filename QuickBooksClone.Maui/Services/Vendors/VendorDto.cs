namespace QuickBooksClone.Maui.Services.Vendors;

public sealed record VendorDto(
    Guid Id,
    string DisplayName,
    string? CompanyName,
    string? Email,
    string? Phone,
    string Currency,
    decimal Balance,
    bool IsActive);
