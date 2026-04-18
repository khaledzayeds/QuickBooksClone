namespace QuickBooksClone.Api.Contracts.PurchaseBills;

public sealed record PurchaseBillLineDto(
    Guid Id,
    Guid ItemId,
    string Description,
    decimal Quantity,
    decimal UnitCost,
    decimal LineTotal);
