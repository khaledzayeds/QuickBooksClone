namespace QuickBooksClone.Api.Contracts.Reports;

public sealed record InventoryValuationReportDto(
    DateOnly FromDate,
    DateOnly ToDate,
    IReadOnlyList<InventoryValuationRowDto> Items,
    decimal TotalOpeningQuantity,
    decimal TotalQuantityIn,
    decimal TotalQuantityOut,
    decimal TotalClosingQuantity,
    decimal TotalOpeningValue,
    decimal TotalQuantityInValue,
    decimal TotalQuantityOutValue,
    decimal TotalClosingValue);
