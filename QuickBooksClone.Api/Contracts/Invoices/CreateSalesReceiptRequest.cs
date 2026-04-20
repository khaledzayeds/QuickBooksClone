using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.Invoices;

public sealed record CreateSalesReceiptRequest(
    Guid CustomerId,
    DateOnly ReceiptDate,
    Guid DepositAccountId,
    string? PaymentMethod,
    [MinLength(1)] IReadOnlyList<CreateInvoiceLineRequest> Lines);
