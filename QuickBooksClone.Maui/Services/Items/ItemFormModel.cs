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

    public decimal SalesPrice { get; set; }
    public decimal PurchasePrice { get; set; }
    public decimal QuantityOnHand { get; set; }

    [StringLength(20)]
    public string Unit { get; set; } = "pcs";

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
            Unit = item.Unit
        };
    }
}
