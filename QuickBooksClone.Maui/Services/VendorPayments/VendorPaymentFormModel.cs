namespace QuickBooksClone.Maui.Services.VendorPayments;

public sealed class VendorPaymentFormModel
{
    public Guid PurchaseBillId { get; set; }
    public Guid PaymentAccountId { get; set; }
    public DateOnly PaymentDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public decimal Amount { get; set; }
    public string PaymentMethod { get; set; } = "Cash";
}
