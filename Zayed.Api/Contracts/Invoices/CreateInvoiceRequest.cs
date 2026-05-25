using System.ComponentModel.DataAnnotations;
using Zayed.Core.Invoices;

namespace Zayed.Api.Contracts.Invoices;

public sealed record CreateInvoiceRequest(
    Guid CustomerId,
    DateOnly InvoiceDate,
    DateOnly DueDate,
    InvoiceSaveMode SaveMode,
    [MinLength(1)] IReadOnlyList<CreateInvoiceLineRequest> Lines);
