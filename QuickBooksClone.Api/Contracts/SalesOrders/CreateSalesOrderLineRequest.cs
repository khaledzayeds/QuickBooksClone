namespace QuickBooksClone.Api.Contracts.SalesOrders;

public sealed record CreateSalesOrderLineRequest(
    Guid ItemId,
    string? Description,
    decimal Quantity,
    decimal UnitPrice,
    Guid? TaxCodeId);
