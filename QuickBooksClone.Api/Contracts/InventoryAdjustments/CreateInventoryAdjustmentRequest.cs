namespace QuickBooksClone.Api.Contracts.InventoryAdjustments;

public sealed record CreateInventoryAdjustmentRequest(
    Guid ItemId,
    Guid AdjustmentAccountId,
    DateOnly AdjustmentDate,
    decimal QuantityChange,
    decimal? UnitCost,
    string? Reason);
