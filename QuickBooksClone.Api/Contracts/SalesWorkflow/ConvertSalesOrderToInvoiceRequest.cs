using QuickBooksClone.Core.Invoices;

namespace QuickBooksClone.Api.Contracts.SalesWorkflow;

public sealed record ConvertSalesOrderToInvoiceRequest(
    DateOnly InvoiceDate,
    DateOnly DueDate,
    InvoiceSaveMode SaveMode,
    IReadOnlyList<ConvertSalesOrderToInvoiceLineRequest> Lines);

public sealed record ConvertSalesOrderToInvoiceLineRequest(
    Guid SalesOrderLineId,
    decimal Quantity,
    decimal DiscountPercent = 0);
