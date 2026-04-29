using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.Invoices;

public sealed record CreateInvoiceLineRequest(
    Guid ItemId,
    [MaxLength(300)] string? Description,
    [Range(0.0001, 999999999)]
    decimal Quantity,
    [Range(0, 999999999)]
    decimal UnitPrice,
    [Range(0, 100)]
    decimal DiscountPercent,
    Guid? TaxCodeId);
