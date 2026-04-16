using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Maui.Services.Accounting;

public sealed class AccountFormModel
{
    [Required(ErrorMessage = "Code is required")]
    [StringLength(20)]
    public string Code { get; set; } = string.Empty;

    [Required(ErrorMessage = "Name is required")]
    [StringLength(150)]
    public string Name { get; set; } = string.Empty;

    public AccountType AccountType { get; set; } = AccountType.Expense;

    [StringLength(500)]
    public string? Description { get; set; }

    public Guid? ParentId { get; set; }

    public static AccountFormModel FromAccount(AccountDto account)
    {
        return new AccountFormModel
        {
            Code = account.Code,
            Name = account.Name,
            AccountType = account.AccountType,
            Description = account.Description,
            ParentId = account.ParentId
        };
    }
}
