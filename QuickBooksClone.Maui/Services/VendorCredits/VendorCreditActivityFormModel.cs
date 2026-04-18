namespace QuickBooksClone.Maui.Services.VendorCredits;

public sealed class VendorCreditActivityFormModel
{
    public Guid VendorId { get; set; }
    public DateOnly ActivityDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public decimal Amount { get; set; }
    public VendorCreditAction Action { get; set; } = VendorCreditAction.ApplyToBill;
    public Guid? PurchaseBillId { get; set; }
    public Guid? DepositAccountId { get; set; }
    public string? PaymentMethod { get; set; } = "Cash";
}
