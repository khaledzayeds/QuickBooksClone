namespace QuickBooksClone.Maui.Services.CustomerCredits;

public sealed class CustomerCreditActivityFormModel
{
    public Guid CustomerId { get; set; }
    public DateOnly ActivityDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public decimal Amount { get; set; }
    public CustomerCreditAction Action { get; set; } = CustomerCreditAction.ApplyToInvoice;
    public Guid? InvoiceId { get; set; }
    public Guid? RefundAccountId { get; set; }
    public string? PaymentMethod { get; set; } = "Cash";
}
