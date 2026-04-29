namespace QuickBooksClone.Api.Contracts.Estimates;

public sealed record EstimateLineDto(
    Guid Id,
    Guid ItemId,
    string Description,
    decimal Quantity,
    decimal UnitPrice,
    Guid? TaxCodeId,
    decimal TaxRatePercent,
    decimal TaxAmount,
    decimal LineTotal);
