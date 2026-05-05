using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.Invoices;

public sealed record UpdateInvoiceRequest(
    Guid CustomerId,
    DateOnly InvoiceDate,
    DateOnly DueDate,
    [MinLength(1)] IReadOnlyList<CreateInvoiceLineRequest> Lines);
