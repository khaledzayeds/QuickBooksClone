using System.ComponentModel.DataAnnotations;

namespace Zayed.Api.Contracts.SalesReturns;

public sealed record CreateSalesReturnRequest(
    Guid InvoiceId,
    DateOnly ReturnDate,
    [MinLength(1)] IReadOnlyList<CreateSalesReturnLineRequest> Lines);
