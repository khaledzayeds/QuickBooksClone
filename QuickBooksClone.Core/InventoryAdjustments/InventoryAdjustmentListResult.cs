namespace QuickBooksClone.Core.InventoryAdjustments;

public sealed record InventoryAdjustmentListResult(IReadOnlyList<InventoryAdjustment> Items, int TotalCount, int Page, int PageSize);
