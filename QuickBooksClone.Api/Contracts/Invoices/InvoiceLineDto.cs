namespace QuickBooksClone.Api.Contracts.Invoices;

public sealed record InvoiceLineDto(
    Guid Id,
    Guid ItemId,
    Guid? SalesOrderLineId,
    string Description,
    decimal Quantity,
    decimal UnitPrice,
    decimal DiscountPercent,
    Guid? TaxCodeId,
    decimal TaxRatePercent,
    decimal TaxAmount,
    decimal LineTotal);
