using QuickBooksClone.Core.SalesOrders;

namespace QuickBooksClone.Api.Contracts.SalesOrders;

public sealed record SalesOrderDto(
    Guid Id,
    string OrderNumber,
    Guid CustomerId,
    string? CustomerName,
    DateOnly OrderDate,
    DateOnly ExpectedDate,
    SalesOrderStatus Status,
    decimal TotalAmount,
    DateTimeOffset? OpenedAt,
    DateTimeOffset? ClosedAt,
    DateTimeOffset? CancelledAt,
    IReadOnlyList<SalesOrderLineDto> Lines);
