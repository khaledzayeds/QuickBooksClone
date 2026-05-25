using Zayed.Core.Invoices;

namespace Zayed.Api.Contracts.SalesWorkflow;

public sealed record ConvertSalesOrderToInvoiceRequest(
    DateOnly InvoiceDate,
    DateOnly DueDate,
    InvoiceSaveMode SaveMode,
    IReadOnlyList<ConvertSalesOrderToInvoiceLineRequest> Lines);

public sealed record ConvertSalesOrderToInvoiceLineRequest(
    Guid SalesOrderLineId,
    decimal Quantity,
    decimal DiscountPercent = 0);
