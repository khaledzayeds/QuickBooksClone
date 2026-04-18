namespace QuickBooksClone.Maui.Services.SalesReturns;

public sealed record SalesReturnLineDto(
    Guid Id,
    Guid InvoiceLineId,
    Guid ItemId,
    string Description,
    decimal Quantity,
    decimal UnitPrice,
    decimal DiscountPercent,
    decimal LineTotal);
