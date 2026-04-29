using QuickBooksClone.Core.SalesOrders;

namespace QuickBooksClone.Api.Contracts.SalesOrders;

public sealed record SalesOrderDto(
    Guid Id,
    string OrderNumber,
    Guid CustomerId,
    string? CustomerName,
    Guid? EstimateId,
    DateOnly OrderDate,
    DateOnly ExpectedDate,
    SalesOrderStatus Status,
    decimal Subtotal,
    decimal TaxAmount,
    decimal TotalAmount,
    DateTimeOffset? OpenedAt,
    DateTimeOffset? ClosedAt,
    DateTimeOffset? CancelledAt,
    IReadOnlyList<SalesOrderLineDto> Lines);
