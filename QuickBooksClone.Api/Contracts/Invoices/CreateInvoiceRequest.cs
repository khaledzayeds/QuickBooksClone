using System.ComponentModel.DataAnnotations;
using QuickBooksClone.Core.Invoices;

namespace QuickBooksClone.Api.Contracts.Invoices;

public sealed record CreateInvoiceRequest(
    Guid CustomerId,
    DateOnly InvoiceDate,
    DateOnly DueDate,
    InvoiceSaveMode SaveMode,
    InvoicePaymentMode PaymentMode,
    Guid? DepositAccountId,
    string? PaymentMethod,
    [MinLength(1)] IReadOnlyList<CreateInvoiceLineRequest> Lines);
