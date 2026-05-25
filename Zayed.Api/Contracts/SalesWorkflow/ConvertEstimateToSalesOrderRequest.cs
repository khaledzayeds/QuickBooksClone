using Zayed.Core.SalesOrders;

namespace Zayed.Api.Contracts.SalesWorkflow;

public sealed record ConvertEstimateToSalesOrderRequest(
    DateOnly OrderDate,
    DateOnly ExpectedDate,
    SalesOrderSaveMode SaveMode,
    IReadOnlyList<ConvertEstimateToSalesOrderLineRequest> Lines);

public sealed record ConvertEstimateToSalesOrderLineRequest(
    Guid EstimateLineId,
    decimal Quantity);
