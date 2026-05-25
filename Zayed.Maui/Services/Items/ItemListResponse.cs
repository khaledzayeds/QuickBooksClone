namespace Zayed.Maui.Services.Items;

public sealed record ItemListResponse(
    IReadOnlyList<ItemDto> Items,
    int TotalCount,
    int Page,
    int PageSize);
