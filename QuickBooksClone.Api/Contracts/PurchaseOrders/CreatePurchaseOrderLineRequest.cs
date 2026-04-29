using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.PurchaseOrders;

public sealed record CreatePurchaseOrderLineRequest(
    Guid ItemId,
    [MaxLength(300)] string? Description,
    [Range(0.01, 999999999)] decimal Quantity,
    [Range(0, 999999999)] decimal UnitCost,
    Guid? TaxCodeId);
