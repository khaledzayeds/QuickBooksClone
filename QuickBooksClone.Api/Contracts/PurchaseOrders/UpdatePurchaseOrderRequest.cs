using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.PurchaseOrders;

public sealed record UpdatePurchaseOrderRequest(
    Guid VendorId,
    DateOnly OrderDate,
    DateOnly ExpectedDate,
    [MinLength(1)] IReadOnlyList<CreatePurchaseOrderLineRequest> Lines);
