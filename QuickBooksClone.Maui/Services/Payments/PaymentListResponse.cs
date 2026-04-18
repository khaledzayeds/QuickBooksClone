namespace QuickBooksClone.Maui.Services.Payments;

public sealed record PaymentListResponse(
    IReadOnlyList<PaymentDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
