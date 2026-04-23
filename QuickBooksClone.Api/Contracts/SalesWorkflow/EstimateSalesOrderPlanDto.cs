using QuickBooksClone.Core.Estimates;
using QuickBooksClone.Core.SalesOrders;

namespace QuickBooksClone.Api.Contracts.SalesWorkflow;

public sealed record EstimateSalesOrderPlanDto(
    Guid EstimateId,
    string EstimateNumber,
    Guid CustomerId,
    string? CustomerName,
    EstimateStatus Status,
    bool CanConvert,
    bool IsFullyConverted,
    decimal TotalEstimatedQuantity,
    decimal TotalOrderedQuantity,
    decimal TotalRemainingQuantity,
    IReadOnlyList<EstimateSalesOrderPlanLineDto> Lines,
    IReadOnlyList<LinkedSalesOrderReferenceDto> LinkedSalesOrders);

public sealed record EstimateSalesOrderPlanLineDto(
    Guid EstimateLineId,
    Guid ItemId,
    string Description,
    decimal EstimatedQuantity,
    decimal OrderedQuantity,
    decimal RemainingQuantity,
    decimal SuggestedOrderQuantity,
    decimal UnitPrice);

public sealed record LinkedSalesOrderReferenceDto(
    Guid Id,
    string OrderNumber,
    DateOnly OrderDate,
    SalesOrderStatus Status);
