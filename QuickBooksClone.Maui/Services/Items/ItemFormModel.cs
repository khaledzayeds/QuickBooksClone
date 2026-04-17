using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Maui.Services.Items;

public sealed class ItemFormModel
{
    [Required(ErrorMessage = "Name is required")]
    [StringLength(200)]
    public string Name { get; set; } = string.Empty;

    public ItemType ItemType { get; set; } = ItemType.Inventory;

    [StringLength(80)]
    public string? Sku { get; set; }

    [StringLength(100)]
    public string? Barcode { get; set; }

    [Range(0, 999999999, ErrorMessage = "Sales price cannot be negative")]
    public decimal SalesPrice { get; set; }

    [Range(0, 999999999, ErrorMessage = "Purchase price cannot be negative")]
    public decimal PurchasePrice { get; set; }

    [Range(0, 999999999, ErrorMessage = "Quantity cannot be negative")]
    public decimal QuantityOnHand { get; set; }

    [StringLength(20)]
    public string Unit { get; set; } = "pcs";

    public Guid? IncomeAccountId { get; set; }
    public Guid? InventoryAssetAccountId { get; set; }
    public Guid? CogsAccountId { get; set; }
    public Guid? ExpenseAccountId { get; set; }

    public static ItemFormModel FromItem(ItemDto item)
    {
        return new ItemFormModel
        {
            Name = item.Name,
            ItemType = item.ItemType,
            Sku = item.Sku,
            Barcode = item.Barcode,
            SalesPrice = item.SalesPrice,
            PurchasePrice = item.PurchasePrice,
            QuantityOnHand = item.QuantityOnHand,
            Unit = item.Unit,
            IncomeAccountId = item.IncomeAccountId,
            InventoryAssetAccountId = item.InventoryAssetAccountId,
            CogsAccountId = item.CogsAccountId,
            ExpenseAccountId = item.ExpenseAccountId
        };
    }
}
