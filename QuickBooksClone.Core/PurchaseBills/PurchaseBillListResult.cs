namespace QuickBooksClone.Core.PurchaseBills;

public sealed record PurchaseBillListResult(
    IReadOnlyList<PurchaseBill> Items,
    int TotalCount,
    int Page,
    int PageSize);
