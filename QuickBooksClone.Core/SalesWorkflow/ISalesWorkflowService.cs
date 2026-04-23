using QuickBooksClone.Core.Estimates;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Payments;
using QuickBooksClone.Core.SalesOrders;

namespace QuickBooksClone.Core.SalesWorkflow;

public interface ISalesWorkflowService
{
    Task<EstimateSalesOrderPlan?> GetEstimateSalesOrderPlanAsync(Guid estimateId, CancellationToken cancellationToken = default);
    Task<SalesOrder?> ConvertEstimateToSalesOrderAsync(Guid estimateId, ConvertEstimateToSalesOrderCommand command, CancellationToken cancellationToken = default);
    Task<SalesOrderInvoicePlan?> GetSalesOrderInvoicePlanAsync(Guid salesOrderId, CancellationToken cancellationToken = default);
    Task<Invoice?> ConvertSalesOrderToInvoiceAsync(Guid salesOrderId, ConvertSalesOrderToInvoiceCommand command, CancellationToken cancellationToken = default);
    Task<InvoicePaymentPlan?> GetInvoicePaymentPlanAsync(Guid invoiceId, CancellationToken cancellationToken = default);
}

public sealed record ConvertEstimateToSalesOrderCommand(
    DateOnly OrderDate,
    DateOnly ExpectedDate,
    SalesOrderSaveMode SaveMode,
    IReadOnlyList<ConvertEstimateToSalesOrderLineCommand> Lines);

public sealed record ConvertEstimateToSalesOrderLineCommand(
    Guid EstimateLineId,
    decimal Quantity);

public sealed record ConvertSalesOrderToInvoiceCommand(
    DateOnly InvoiceDate,
    DateOnly DueDate,
    InvoiceSaveMode SaveMode,
    IReadOnlyList<ConvertSalesOrderToInvoiceLineCommand> Lines);

public sealed record ConvertSalesOrderToInvoiceLineCommand(
    Guid SalesOrderLineId,
    decimal Quantity,
    decimal DiscountPercent = 0);

public sealed record EstimateSalesOrderPlan(
    Guid EstimateId,
    string EstimateNumber,
    Guid CustomerId,
    EstimateStatus Status,
    bool CanConvert,
    bool IsFullyConverted,
    decimal TotalEstimatedQuantity,
    decimal TotalOrderedQuantity,
    decimal TotalRemainingQuantity,
    IReadOnlyList<EstimateSalesOrderPlanLine> Lines,
    IReadOnlyList<LinkedSalesOrderReference> LinkedSalesOrders);

public sealed record EstimateSalesOrderPlanLine(
    Guid EstimateLineId,
    Guid ItemId,
    string Description,
    decimal EstimatedQuantity,
    decimal OrderedQuantity,
    decimal RemainingQuantity,
    decimal SuggestedOrderQuantity,
    decimal UnitPrice);

public sealed record SalesOrderInvoicePlan(
    Guid SalesOrderId,
    string OrderNumber,
    Guid CustomerId,
    Guid? EstimateId,
    SalesOrderStatus Status,
    bool CanConvert,
    bool IsFullyInvoiced,
    decimal TotalOrderedQuantity,
    decimal TotalInvoicedQuantity,
    decimal TotalRemainingQuantity,
    IReadOnlyList<SalesOrderInvoicePlanLine> Lines,
    IReadOnlyList<LinkedInvoiceReference> LinkedInvoices);

public sealed record SalesOrderInvoicePlanLine(
    Guid SalesOrderLineId,
    Guid ItemId,
    Guid? EstimateLineId,
    string Description,
    decimal OrderedQuantity,
    decimal InvoicedQuantity,
    decimal RemainingQuantity,
    decimal SuggestedInvoiceQuantity,
    decimal UnitPrice);

public sealed record InvoicePaymentPlan(
    Guid InvoiceId,
    string InvoiceNumber,
    Guid CustomerId,
    Guid? SalesOrderId,
    InvoiceStatus Status,
    bool CanReceivePayment,
    bool IsFullyPaid,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal CreditAppliedAmount,
    decimal ReturnedAmount,
    decimal BalanceDue,
    IReadOnlyList<LinkedPaymentReference> LinkedPayments);

public sealed record LinkedSalesOrderReference(
    Guid Id,
    string OrderNumber,
    DateOnly OrderDate,
    SalesOrderStatus Status);

public sealed record LinkedInvoiceReference(
    Guid Id,
    string InvoiceNumber,
    DateOnly InvoiceDate,
    InvoiceStatus Status);

public sealed record LinkedPaymentReference(
    Guid Id,
    string PaymentNumber,
    DateOnly PaymentDate,
    PaymentStatus Status,
    decimal Amount);
