namespace QuickBooksClone.Maui.Services.Payments;

public sealed class PaymentFormModel
{
    public Guid InvoiceId { get; set; }
    public Guid DepositAccountId { get; set; }
    public DateOnly PaymentDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public decimal Amount { get; set; }
    public string PaymentMethod { get; set; } = "Cash";
}
