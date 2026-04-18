using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.PurchaseReturns;

public sealed record CreatePurchaseReturnRequest(
    Guid PurchaseBillId,
    DateOnly ReturnDate,
    [MinLength(1)] IReadOnlyList<CreatePurchaseReturnLineRequest> Lines);
