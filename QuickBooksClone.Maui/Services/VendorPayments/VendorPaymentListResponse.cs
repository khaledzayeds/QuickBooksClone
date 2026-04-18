namespace QuickBooksClone.Maui.Services.VendorPayments;

public sealed record VendorPaymentListResponse(
    IReadOnlyList<VendorPaymentDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
