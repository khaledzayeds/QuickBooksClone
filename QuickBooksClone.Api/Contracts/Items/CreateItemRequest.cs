using System.ComponentModel.DataAnnotations;
using QuickBooksClone.Core.Items;

namespace QuickBooksClone.Api.Contracts.Items;

public sealed record CreateItemRequest(
    [Required, MaxLength(200)] string Name,
    ItemType ItemType,
    [MaxLength(80)] string? Sku,
    [MaxLength(100)] string? Barcode,
    [Range(0, 999999999)]
    decimal SalesPrice,
    [Range(0, 999999999)]
    decimal PurchasePrice,
    [Range(0, 999999999)]
    decimal QuantityOnHand,
    [MaxLength(20)] string? Unit,
    Guid? IncomeAccountId,
    Guid? InventoryAssetAccountId,
    Guid? CogsAccountId,
    Guid? ExpenseAccountId);
