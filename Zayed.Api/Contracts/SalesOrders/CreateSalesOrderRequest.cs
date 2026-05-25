using Zayed.Core.SalesOrders;

namespace Zayed.Api.Contracts.SalesOrders;

public sealed record CreateSalesOrderRequest(
    Guid CustomerId,
    DateOnly OrderDate,
    DateOnly ExpectedDate,
    SalesOrderSaveMode SaveMode,
    IReadOnlyList<CreateSalesOrderLineRequest> Lines);
