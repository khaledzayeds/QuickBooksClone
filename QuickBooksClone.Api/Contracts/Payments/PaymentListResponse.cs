namespace QuickBooksClone.Api.Contracts.Payments;

public sealed record PaymentListResponse(
    IReadOnlyList<PaymentDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
