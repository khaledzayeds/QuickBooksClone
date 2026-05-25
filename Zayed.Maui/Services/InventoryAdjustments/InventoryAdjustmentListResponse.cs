namespace Zayed.Maui.Services.InventoryAdjustments;

public sealed record InventoryAdjustmentListResponse(IReadOnlyList<InventoryAdjustmentDto> Items, int TotalCount, int Page, int PageSize);
