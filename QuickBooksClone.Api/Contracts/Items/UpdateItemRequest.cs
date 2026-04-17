using System.ComponentModel.DataAnnotations;
using QuickBooksClone.Core.Items;

namespace QuickBooksClone.Api.Contracts.Items;

public sealed record UpdateItemRequest(
    [Required, MaxLength(200)] string Name,
    ItemType ItemType,
    [MaxLength(80)] string? Sku,
    [MaxLength(100)] string? Barcode,
    decimal SalesPrice,
    decimal PurchasePrice,
    [MaxLength(20)] string? Unit,
    Guid? IncomeAccountId,
    Guid? InventoryAssetAccountId,
    Guid? CogsAccountId,
    Guid? ExpenseAccountId);
