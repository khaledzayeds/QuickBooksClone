using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.Invoices;

public sealed record CreateInvoiceLineRequest(
    Guid ItemId,
    [MaxLength(300)] string? Description,
    decimal Quantity,
    decimal UnitPrice,
    decimal DiscountPercent);
