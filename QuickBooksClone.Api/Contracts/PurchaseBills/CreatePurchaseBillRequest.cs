using System.ComponentModel.DataAnnotations;
using QuickBooksClone.Core.PurchaseBills;

namespace QuickBooksClone.Api.Contracts.PurchaseBills;

public sealed record CreatePurchaseBillRequest(
    Guid VendorId,
    DateOnly BillDate,
    DateOnly DueDate,
    PurchaseBillSaveMode SaveMode,
    [MinLength(1)] IReadOnlyList<CreatePurchaseBillLineRequest> Lines);
