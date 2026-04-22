namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record InventoryValuationRowDto(
    Guid ItemId,
    string ItemName,
    string? Sku,
    string Unit,
    decimal UnitCost,
    decimal OpeningQuantity,
    decimal QuantityIn,
    decimal QuantityOut,
    decimal ClosingQuantity,
    decimal OpeningValue,
    decimal QuantityInValue,
    decimal QuantityOutValue,
    decimal ClosingValue);
