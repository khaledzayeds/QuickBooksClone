using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Maui.Services.SalesReceipts;

public sealed class SalesReceiptFormModel
{
    [Required]
    public Guid CustomerId { get; set; }

    [Required]
    public Guid DepositAccountId { get; set; }

    public DateOnly ReceiptDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public string? PaymentMethod { get; set; } = "Cash";
    public List<SalesReceiptLineFormModel> Lines { get; } = [];
}

public sealed class SalesReceiptLineFormModel
{
    [Required]
    public Guid ItemId { get; set; }

    public string? Description { get; set; }
    public decimal Quantity { get; set; } = 1;
    public decimal UnitPrice { get; set; }
    public decimal DiscountPercent { get; set; }
}
