namespace QuickBooksClone.Api.Contracts.SalesOrders;

public sealed record SalesOrderLineDto(
    Guid Id,
    Guid ItemId,
    string Description,
    decimal Quantity,
    decimal UnitPrice,
    decimal LineTotal);
