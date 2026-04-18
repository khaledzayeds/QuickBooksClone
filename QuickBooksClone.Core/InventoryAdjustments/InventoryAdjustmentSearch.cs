namespace QuickBooksClone.Core.InventoryAdjustments;

public sealed record InventoryAdjustmentSearch(
    string? Search = null,
    Guid? ItemId = null,
    bool IncludeVoid = false,
    int Page = 1,
    int PageSize = 25);
