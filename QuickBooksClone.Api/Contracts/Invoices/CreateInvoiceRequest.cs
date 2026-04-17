using System.ComponentModel.DataAnnotations;
using QuickBooksClone.Core.Invoices;

namespace QuickBooksClone.Api.Contracts.Invoices;

public sealed record CreateInvoiceRequest(
    Guid CustomerId,
    DateOnly InvoiceDate,
    DateOnly DueDate,
    InvoiceSaveMode SaveMode,
    [MinLength(1)] IReadOnlyList<CreateInvoiceLineRequest> Lines);
