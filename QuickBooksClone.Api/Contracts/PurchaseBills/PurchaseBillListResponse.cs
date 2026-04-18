namespace QuickBooksClone.Api.Contracts.PurchaseBills;

public sealed record PurchaseBillListResponse(
    IReadOnlyList<PurchaseBillDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
