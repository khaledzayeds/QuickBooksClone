using System.ComponentModel.DataAnnotations;
using QuickBooksClone.Core.Items;

namespace QuickBooksClone.Api.Contracts.Items;

public sealed record CreateItemRequest(
    [Required, MaxLength(200)] string Name,
    ItemType ItemType,
    [MaxLength(80)] string? Sku,
    [MaxLength(100)] string? Barcode,
    decimal SalesPrice,
    decimal PurchasePrice,
    decimal QuantityOnHand,
    [MaxLength(20)] string? Unit);
