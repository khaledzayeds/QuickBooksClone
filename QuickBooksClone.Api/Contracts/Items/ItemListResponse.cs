namespace QuickBooksClone.Api.Contracts.Items;

public sealed record ItemListResponse(
    IReadOnlyList<ItemDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
