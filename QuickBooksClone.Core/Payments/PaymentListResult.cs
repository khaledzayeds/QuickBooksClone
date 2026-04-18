namespace QuickBooksClone.Core.Payments;

public sealed record PaymentListResult(
    IReadOnlyList<Payment> Items,
    int TotalCount,
    int Page,
    int PageSize);
