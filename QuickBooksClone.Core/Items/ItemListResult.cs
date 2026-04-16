namespace QuickBooksClone.Core.Items;

public sealed record ItemListResult(
    IReadOnlyList<Item> Items,
    int TotalCount,
    int Page,
    int PageSize);
