namespace QuickBooksClone.Api.Contracts.InventoryAdjustments;

public sealed record InventoryAdjustmentListResponse(IReadOnlyList<InventoryAdjustmentDto> Items, int TotalCount, int Page, int PageSize);
