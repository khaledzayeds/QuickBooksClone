namespace QuickBooksClone.Api.Contracts.SalesReturns;

public sealed record SalesReturnListResponse(
    IReadOnlyList<SalesReturnDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
