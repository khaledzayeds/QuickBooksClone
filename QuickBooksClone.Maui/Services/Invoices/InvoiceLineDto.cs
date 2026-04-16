namespace QuickBooksClone.Maui.Services.Invoices;

public sealed record InvoiceLineDto(
    Guid Id,
    Guid ItemId,
    string Description,
    decimal Quantity,
    decimal UnitPrice,
    decimal DiscountPercent,
    decimal LineTotal);
