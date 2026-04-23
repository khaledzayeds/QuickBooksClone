using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.SalesOrders;

namespace QuickBooksClone.Api.Contracts.SalesWorkflow;

public sealed record SalesOrderInvoicePlanDto(
    Guid SalesOrderId,
    string OrderNumber,
    Guid CustomerId,
    string? CustomerName,
    Guid? EstimateId,
    string? EstimateNumber,
    SalesOrderStatus Status,
    bool CanConvert,
    bool IsFullyInvoiced,
    decimal TotalOrderedQuantity,
    decimal TotalInvoicedQuantity,
    decimal TotalRemainingQuantity,
    IReadOnlyList<SalesOrderInvoicePlanLineDto> Lines,
    IReadOnlyList<LinkedInvoiceReferenceDto> LinkedInvoices);

public sealed record SalesOrderInvoicePlanLineDto(
    Guid SalesOrderLineId,
    Guid ItemId,
    Guid? EstimateLineId,
    string Description,
    decimal OrderedQuantity,
    decimal InvoicedQuantity,
    decimal RemainingQuantity,
    decimal SuggestedInvoiceQuantity,
    decimal UnitPrice);

public sealed record LinkedInvoiceReferenceDto(
    Guid Id,
    string InvoiceNumber,
    DateOnly InvoiceDate,
    InvoiceStatus Status);
