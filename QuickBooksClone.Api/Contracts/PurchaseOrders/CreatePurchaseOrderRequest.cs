using System.ComponentModel.DataAnnotations;
using QuickBooksClone.Core.PurchaseOrders;

namespace QuickBooksClone.Api.Contracts.PurchaseOrders;

public sealed record CreatePurchaseOrderRequest(
    Guid VendorId,
    DateOnly OrderDate,
    DateOnly ExpectedDate,
    PurchaseOrderSaveMode SaveMode,
    [MinLength(1)] IReadOnlyList<CreatePurchaseOrderLineRequest> Lines);
