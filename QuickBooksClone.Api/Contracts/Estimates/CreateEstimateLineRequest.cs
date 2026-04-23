namespace QuickBooksClone.Api.Contracts.Estimates;

public sealed record CreateEstimateLineRequest(
    Guid ItemId,
    string? Description,
    decimal Quantity,
    decimal UnitPrice);
