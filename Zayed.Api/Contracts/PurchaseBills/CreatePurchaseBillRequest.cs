using System.ComponentModel.DataAnnotations;
using Zayed.Core.PurchaseBills;

namespace Zayed.Api.Contracts.PurchaseBills;

public sealed record CreatePurchaseBillRequest(
    Guid VendorId,
    Guid? InventoryReceiptId,
    DateOnly BillDate,
    DateOnly DueDate,
    PurchaseBillSaveMode SaveMode,
    [MinLength(1)] IReadOnlyList<CreatePurchaseBillLineRequest> Lines);
