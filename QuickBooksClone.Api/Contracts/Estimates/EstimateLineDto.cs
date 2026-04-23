namespace QuickBooksClone.Api.Contracts.Estimates;

public sealed record EstimateLineDto(
    Guid Id,
    Guid ItemId,
    string Description,
    decimal Quantity,
    decimal UnitPrice,
    decimal LineTotal);
