using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Maui.Services.Customers;

public sealed class CustomerFormModel
{
    [Required(ErrorMessage = "Display name is required")]
    [StringLength(200)]
    public string DisplayName { get; set; } = string.Empty;

    [StringLength(200)]
    public string? CompanyName { get; set; }

    [EmailAddress]
    [StringLength(150)]
    public string? Email { get; set; }

    [StringLength(30)]
    public string? Phone { get; set; }

    [StringLength(3, MinimumLength = 3)]
    public string Currency { get; set; } = "EGP";

    [Range(0, 999999999, ErrorMessage = "Opening balance cannot be negative")]
    public decimal OpeningBalance { get; set; }

    public static CustomerFormModel FromCustomer(CustomerDto customer)
    {
        return new CustomerFormModel
        {
            DisplayName = customer.DisplayName,
            CompanyName = customer.CompanyName,
            Email = customer.Email,
            Phone = customer.Phone,
            Currency = customer.Currency,
            OpeningBalance = customer.Balance
        };
    }
}
