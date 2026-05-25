namespace Zayed.Core.VendorPayments;

public sealed record VendorPaymentListResult(
    IReadOnlyList<VendorPayment> Items,
    int TotalCount,
    int Page,
    int PageSize);
