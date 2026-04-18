namespace QuickBooksClone.Maui.Services.InventoryAdjustments;

public sealed record InventoryAdjustmentDto(
    Guid Id,
    string AdjustmentNumber,
    Guid ItemId,
    string? ItemName,
    Guid AdjustmentAccountId,
    string? AdjustmentAccountName,
    DateOnly AdjustmentDate,
    decimal QuantityChange,
    decimal UnitCost,
    decimal TotalCost,
    string Reason,
    InventoryAdjustmentStatus Status,
    Guid? PostedTransactionId,
    DateTimeOffset? PostedAt);
