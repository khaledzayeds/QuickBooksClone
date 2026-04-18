using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.SalesReturns;

public sealed record CreateSalesReturnLineRequest(
    Guid InvoiceLineId,
    decimal Quantity,
    decimal? UnitPrice,
    [Range(0, 100)] decimal DiscountPercent);
