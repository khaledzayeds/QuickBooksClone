namespace Zayed.Core.Items;

public static class ItemTypeBehavior
{
    public static bool TracksInventory(ItemType itemType) =>
        itemType is ItemType.Inventory or ItemType.InventoryAssembly;

    public static bool PostsThroughComponents(ItemType itemType) =>
        itemType is ItemType.Bundle or ItemType.Group;

    public static bool IsSubtotal(ItemType itemType) =>
        itemType == ItemType.Subtotal;

    public static bool IsDiscount(ItemType itemType) =>
        itemType == ItemType.Discount;

    public static bool IsPayment(ItemType itemType) =>
        itemType == ItemType.Payment;

    public static bool IsAmountReducingLine(ItemType itemType) =>
        itemType is ItemType.Discount or ItemType.Payment;

    public static bool CanApplySalesTax(ItemType itemType) =>
        itemType is not (ItemType.Discount or ItemType.Payment or ItemType.Subtotal or ItemType.Bundle or ItemType.Group);

    public static decimal ResolveSalesUnitPrice(Item item, decimal requestedUnitPrice)
    {
        if (IsSubtotal(item.ItemType) || PostsThroughComponents(item.ItemType))
        {
            return 0;
        }

        var amount = requestedUnitPrice > 0 ? requestedUnitPrice : item.SalesPrice;
        return IsAmountReducingLine(item.ItemType) ? -Math.Abs(amount) : amount;
    }

    public static decimal ResolveSalesDiscountPercent(ItemType itemType, decimal requestedDiscountPercent) =>
        IsAmountReducingLine(itemType) || IsSubtotal(itemType) ? 0 : requestedDiscountPercent;
}
