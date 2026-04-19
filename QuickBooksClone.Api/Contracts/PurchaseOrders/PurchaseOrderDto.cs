using QuickBooksClone.Core.PurchaseOrders;

namespace QuickBooksClone.Api.Contracts.PurchaseOrders;

public sealed record PurchaseOrderDto(
    Guid Id,
    string OrderNumber,
    Guid VendorId,
    string? VendorName,
    DateOnly OrderDate,
    DateOnly ExpectedDate,
    PurchaseOrderStatus Status,
    decimal TotalAmount,
    DateTimeOffset? OpenedAt,
    DateTimeOffset? ClosedAt,
    DateTimeOffset? CancelledAt,
    IReadOnlyList<PurchaseOrderLineDto> Lines);
