using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.Vendors;

public sealed record UpdateVendorRequest(
    [Required, MaxLength(200)] string DisplayName,
    [MaxLength(200)] string? CompanyName,
    [EmailAddress, MaxLength(150)] string? Email,
    [MaxLength(30)] string? Phone,
    [MaxLength(3)] string? Currency);
