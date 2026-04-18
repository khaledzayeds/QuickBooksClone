using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Maui.Services.Invoices;

public sealed class InvoiceFormModel
{
    [Required]
    public Guid CustomerId { get; set; }

    public DateOnly InvoiceDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public DateOnly DueDate { get; set; } = DateOnly.FromDateTime(DateTime.Today.AddDays(30));
    public InvoiceSaveMode SaveMode { get; set; } = InvoiceSaveMode.SaveAndPost;
    public InvoicePaymentMode PaymentMode { get; set; } = InvoicePaymentMode.Credit;
    public Guid? DepositAccountId { get; set; }
    public string? PaymentMethod { get; set; } = "Cash";
    public List<InvoiceLineFormModel> Lines { get; } = [];
}

public sealed class InvoiceLineFormModel
{
    [Required]
    public Guid ItemId { get; set; }

    public string? Description { get; set; }
    public decimal Quantity { get; set; } = 1;
    public decimal UnitPrice { get; set; }
    public decimal DiscountPercent { get; set; }
}
